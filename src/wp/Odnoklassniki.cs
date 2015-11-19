using System;
using System.IO;
using System.Net;
using System.Collections.Generic;
using System.Text;
using Microsoft.Phone.Controls;
using System.Windows.Navigation;
using System.IO.IsolatedStorage;
using Odnoklassniki.ServiceStructures;
using System.ComponentModel;
using System.Linq;

// ReSharper disable once CheckNamespace
namespace Odnoklassniki
{
// ReSharper disable once InconsistentNaming
    class SDK
    {
        /// <summary>
        /// Parameters name prefix that will be used to store parameters in application isolated storage.
        /// </summary>
        [DefaultValue("OK_SDK_")]
        public static string SettingsPrefix{get; set;}
        /*
         * Error strings.
         * If you see these errors, see documentation here http://apiok.ru/ .
         */
        public const string ErrorSessionExpired = "SESSION_EXPIRED";
        public const string ErrorNoTokenSentByServer = "NO_ACCESS_TOKEN_SENT_BY_SERVER";
        public const string ErrorBadApiRequest = "BAD_API_REQUEST";
        /*
         * Uris, uri templates, data templates
         */
        private const string UriApiRequest = "http://api.odnoklassniki.ru/fb.do";
        private const string UriTokenRequest = "http://api.odnoklassniki.ru/oauth/token.do";
        private const string UriTemplateAuth = "http://www.odnoklassniki.ru/oauth/authorize?client_id={0}&scope={1}&response_type=code&redirect_uri={2}&layout=m";
        private const string DataTemplateAuthTokenRequest = "code={0}&redirect_uri={1}&grant_type=authorization_code&client_id={2}&client_secret={3}";
        private const string DataTemplateAuthTokenUpdateRequest = "refresh_token={0}&grant_type=refresh_token&client_id={1}&client_secret={2}";

        private const string SdkException = "Odnoklassniki sdk exception. Please, check your app info, request correctness and internet connection. If problem persists, contact SDK developers with error and your actions description.";
        private const string ParameterNameAccessToken = "access_token";
        private const string ParameterNameRefreshToken = "refresh_token";
        private const string ResponsePartErrorCode = "\"error_code\"";
        private const int ErrorCodeSessionExpired = 102;

        private readonly string _appId;
        private readonly string _appPublicKey;
        private readonly string _appSecretKey;
        private readonly string _redirectUrl;
        private readonly string _permissions;
        private string _accessToken;
        private string _refreshToken;
        private string _code;
        private readonly ConcurrentDictionary<HttpWebRequest, CallbackStruct> _callbacks = new ConcurrentDictionary<HttpWebRequest, CallbackStruct>();
        private AuthCallbackStruct _authCallback, _updateCallback;

        private enum OAuthRequestType : byte { OAuthTypeAuth, OAuthTypeUpdateToken };

        public SDK(string applicationId, string applicationPublicKey, string applicationSecretKey, string redirectUrl, string permissions)
        {

            this._appId = applicationId;
            this._appPublicKey = applicationPublicKey;
            this._appSecretKey = applicationSecretKey;
            this._redirectUrl = redirectUrl;
            this._permissions = permissions;
        }

        /// <summary>
        /// Authorize the application with permissions.
        /// Calls onSuccess after correct response, onError otherwise(in callbackContext thread).
        /// </summary>
        /// <param name="browser">browser element will be used for OAuth2 authorisation.</param>
        /// <param name="callbackContext">PhoneApplicationPage in context of witch RequestCallback would be called. Used to make working with UI components from callbacks simplier.</param>
        /// <param name="onSuccess">this function will be called after success authorisation(in callbackContext thread)</param>
        /// <param name="onError">this function will be called after unsuccess authorisation(in callbackContext thread)</param>
        /// <param name="saveSession">if true, saves refresh ann access tokens to application islolated storage</param>
        public void Authorize(WebBrowser browser, PhoneApplicationPage callbackContext, Action onSuccess, Action<Exception> onError, bool saveSession = true)
        {
            this._authCallback.OnSuccess = onSuccess;
            this._authCallback.OnError = onError;
            this._authCallback.CallbackContext = callbackContext;
            this._authCallback.SaveSession = saveSession;
            Uri uri = new Uri(String.Format(UriTemplateAuth, this._appId, this._permissions, this._redirectUrl), UriKind.Absolute);
            browser.Navigated += NavigateHandler;
            browser.Navigate(uri);
        }

        /// <summary>
        /// Prepairs and sends API request.
        /// Calls onSuccess after correct response, onError otherwise(in callbackContext thread).
        /// </summary>
        /// <param name="method">methodname</param>
        /// <param name="parameters">dictionary "parameter_name":"parameter_value"</param>
        /// <param name="callbackContext">PhoneApplicationPage in context of witch RequestCallback would be called. Used to make working with UI components from callbacks simplier.</param>
        /// <param name="onSuccess">this function will be called after success authorisation(in callbackContext thread)</param>
        /// <param name="onError">this function will be called after unsuccess authorisation(in callbackContext thread)</param>
        public void SendRequest(string method, Dictionary<string, string> parameters, PhoneApplicationPage callbackContext, Action<string> onSuccess, Action<Exception> onError)
        {
            try
            {
                Dictionary<string, string> parametersLocal = parameters == null ? new Dictionary<string, string>() : new Dictionary<string, string>(parameters);
                StringBuilder builder = new StringBuilder(UriApiRequest).Append("?");
                parametersLocal.Add("sig", this.CalcSignature(method, parameters));
                parametersLocal.Add("application_key", this._appPublicKey);
                parametersLocal.Add("method", method);
                parametersLocal.Add(ParameterNameAccessToken, this._accessToken);
                foreach (KeyValuePair<string, string> pair in parametersLocal)
                {
                    builder.Append(pair.Key).Append("=").Append(pair.Value).Append("&");
                }
                // removing last & added with cycle
                builder.Remove(builder.Length - 1, 1);
                HttpWebRequest request = WebRequest.CreateHttp(builder.ToString());
                CallbackStruct callbackStruct;
                callbackStruct.OnSuccess = onSuccess;
                callbackStruct.CallbackContext = callbackContext;
                callbackStruct.OnError = onError;
                this._callbacks.SafeAdd(request, callbackStruct);
                request.BeginGetResponse(this.RequestCallback, request);
            }
            catch (Exception e)
            {
                if (onError != null)
                {
                    onError.Invoke(new Exception(SdkException, e));
                }
            }
        }

        /// <summary>
        /// Tries to update access_token with refresh_token.
        /// Calls onSuccess after correct response, onError otherwise(in callbackContext thread).
        /// </summary>
        /// <param name="callbackContext">PhoneApplicationPage in context of witch RequestCallback would be called. Used to make working with UI components from callbacks simplier.</param>
        /// <param name="onSuccess">this function will be called after success authorisation(in callbackContext thread)</param>
        /// <param name="onError">this function will be called after unsuccess authorisation(in callbackContext thread)</param>
        /// <param name="saveSession">if true, saves new access token to application isolated storage</param>
        public void UpdateToken(PhoneApplicationPage callbackContext, Action onSuccess, Action<Exception> onError, bool saveSession = true)
        {
            this._updateCallback.CallbackContext = callbackContext;
            this._updateCallback.OnSuccess = onSuccess;
            this._updateCallback.SaveSession = saveSession;
            this._updateCallback.OnError = onError;
            try
            {
                BeginOAuthRequest(SDK.OAuthRequestType.OAuthTypeUpdateToken);
            }
            catch(Exception e)
            {
                if (onError != null)
                {
                    onError.Invoke(new Exception(SdkException, e));
                }
            }
        }
 
        /// <summary>
        /// Saves acces_token and refresh_token to application isolated storage.
        /// </summary>
        public void SaveSession()
        {
            try
            {
                IsolatedStorageSettings appSettings = IsolatedStorageSettings.ApplicationSettings;
                appSettings[SDK.SettingsPrefix + SDK.ParameterNameAccessToken] = this._accessToken;
                appSettings[SDK.SettingsPrefix + SDK.ParameterNameRefreshToken] = this._refreshToken;
                appSettings.Save();
            }
            catch (IsolatedStorageException e)
            {
                throw new Exception(SdkException, e);
            }
        }

        /// <summary>
        /// Tries to load acces_token and refresh_token from application isolated storage.
        /// This function doesn't guarantee, that tokens are correct.
        /// <returns>Returns true if access_tokent and refresh_token loaded from isolated storage false otherwise.</returns>
        /// </summary>
        public bool TryLoadSession()
        {
            IsolatedStorageSettings appSettings = IsolatedStorageSettings.ApplicationSettings;
            if (appSettings.Contains(SDK.SettingsPrefix + SDK.ParameterNameAccessToken) && appSettings.Contains(SDK.SettingsPrefix + SDK.ParameterNameRefreshToken))
            {
                this._accessToken = (string)appSettings[SDK.SettingsPrefix + SDK.ParameterNameAccessToken];
                this._refreshToken = (string)appSettings[SDK.SettingsPrefix + SDK.ParameterNameRefreshToken];
                return this._accessToken != null && this._refreshToken != null;
            }
            return false;
        }

        /// <summary>
        /// Removes access_token and refresh_token from appliction isolated storage and object.
        /// You have to get new tokens usin Authorise method after calling this method.
        /// </summary>
        public void ResetSession()
        {
            this._accessToken = null;
            this._refreshToken = null;
            IsolatedStorageSettings appSettings = IsolatedStorageSettings.ApplicationSettings;
            appSettings.Remove(SDK.SettingsPrefix + SDK.ParameterNameAccessToken);
            appSettings.Remove(SDK.SettingsPrefix + SDK.ParameterNameRefreshToken);
        }

        #region functions used for authorisation and updating token

        private void NavigateHandler(object sender, NavigationEventArgs e)
        {
            try
            {
                const string codeIs = "code=", errorIs = "error=";
                string query = e.Uri.Query;
                if (query.IndexOf(codeIs, System.StringComparison.OrdinalIgnoreCase) != -1)
                {
                    this._code = query.Substring(query.IndexOf(codeIs, System.StringComparison.OrdinalIgnoreCase) + codeIs.Length);
                    this.BeginOAuthRequest(SDK.OAuthRequestType.OAuthTypeAuth);
                }
                else if (query.IndexOf(errorIs, System.StringComparison.OrdinalIgnoreCase) != -1)
                {
                    throw new Exception(query.Substring(query.IndexOf(errorIs, System.StringComparison.OrdinalIgnoreCase) + errorIs.Length));
                }
            }
            catch (Exception ex)
            {
                ProcessOAuthError(new Exception(SdkException, ex), SDK.OAuthRequestType.OAuthTypeAuth);
            }
        }

        private void BeginOAuthRequest(SDK.OAuthRequestType type)
        {
            try
            {
                Uri myUri = new Uri(UriTokenRequest);
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(myUri);
                request.Method = "POST";
                request.ContentType = "application/x-www-form-urlencoded";
                request.BeginGetRequestStream(arg => BeginGetOAuthResponse(arg, type), request);

            }
            catch (Exception e)
            {
                ProcessOAuthError(new Exception(SdkException, e), type);
            }
        }

        private void BeginGetOAuthResponse(IAsyncResult result, SDK.OAuthRequestType type)
        {
            try
            {
                HttpWebRequest request = (HttpWebRequest)result.AsyncState; 
                Stream postStream = request.EndGetRequestStream(result);

                string parameters = null;
                if (type == SDK.OAuthRequestType.OAuthTypeAuth)
                {
                    parameters = String.Format(DataTemplateAuthTokenRequest, new object[] {this._code, this._redirectUrl, this._appId, this._appSecretKey});
                }
                else if (type == SDK.OAuthRequestType.OAuthTypeUpdateToken)
                {
                    parameters = String.Format(DataTemplateAuthTokenUpdateRequest, this._refreshToken, this._appId, this._appSecretKey);
                }
                // ReSharper disable once AssignNullToNotNullAttribute
                // for now, it's correct to throw ArgumentNullException, if it'll be
                byte[] byteArray = Encoding.UTF8.GetBytes(parameters);

                postStream.Write(byteArray, 0, byteArray.Length);
                postStream.Close();

                request.BeginGetResponse(arg => ProcessOAuthResponse(arg, type), request);
            }
            catch (Exception e)
            {
                ProcessOAuthError(new Exception(SdkException, e), type);
            }
        }

        private void ProcessOAuthResponse(IAsyncResult callbackResult, SDK.OAuthRequestType type)
        {
            try
            {
                HttpWebRequest request = (HttpWebRequest)callbackResult.AsyncState;
                HttpWebResponse response = (HttpWebResponse)request.EndGetResponse(callbackResult);
                using (StreamReader httpWebStreamReader = new StreamReader(response.GetResponseStream()))
                {
                    string result = httpWebStreamReader.ReadToEnd();
                    int tokenPosition = result.IndexOf(ParameterNameAccessToken, System.StringComparison.OrdinalIgnoreCase);
                    if(tokenPosition != 0)
                    {
                        const string tokenNameValueSeparator = "\":\"";
                        const char tokenStopSymbol = '\"';
                        StringBuilder builder = new StringBuilder();
                        tokenPosition += SDK.ParameterNameAccessToken.Length + tokenNameValueSeparator.Length;
                        while (tokenPosition < result.Length && !result[tokenPosition].Equals(tokenStopSymbol))
                        {
                            builder.Append(result[tokenPosition]);
                            tokenPosition++;
                        }
                        this._accessToken = builder.ToString();
                        AuthCallbackStruct callbackStruct = this._updateCallback;
                        if (type == SDK.OAuthRequestType.OAuthTypeAuth)
                        {
                            builder.Clear();
                            tokenPosition = result.IndexOf(SDK.ParameterNameRefreshToken, System.StringComparison.OrdinalIgnoreCase) + SDK.ParameterNameRefreshToken.Length + tokenNameValueSeparator.Length;
                            while (tokenPosition < result.Length && !result[tokenPosition].Equals(tokenStopSymbol))
                            {
                                builder.Append(result[tokenPosition]);
                                tokenPosition++;
                            }
                            this._refreshToken = builder.ToString();

                            callbackStruct = this._authCallback;
                        }
                        if (callbackStruct.SaveSession)
                        {
                            SaveSession();
                        }
                        if (callbackStruct.CallbackContext != null && callbackStruct.OnSuccess != null)
                        {
                            callbackStruct.CallbackContext.Dispatcher.BeginInvoke(() => callbackStruct.OnSuccess.Invoke());
                        }
                    }
                    else
                    {
                        ProcessOAuthError(new Exception(ErrorNoTokenSentByServer), type);
                    }
                }
            }
            catch (Exception e)
            {
                ProcessOAuthError(e, type);
            }
        }

        private void ProcessOAuthError(Exception e, SDK.OAuthRequestType type)
        {
            if (type == SDK.OAuthRequestType.OAuthTypeAuth && this._authCallback.OnError != null && this._authCallback.CallbackContext != null)
            {
                this._authCallback.CallbackContext.Dispatcher.BeginInvoke(() => this._authCallback.OnError.Invoke(e));
            }
            else if (type == SDK.OAuthRequestType.OAuthTypeUpdateToken && this._updateCallback.OnError != null)
            {
                this._updateCallback.CallbackContext.Dispatcher.BeginInvoke(() => this._updateCallback.OnError.Invoke(e));
            }
        }

        #endregion

        /// <summary>
        /// Callback for SendRequest function.
        /// Checks for errors and calls callback for each API request.
        /// </summary>
        private void RequestCallback(IAsyncResult result)
        {
            HttpWebRequest request = result.AsyncState as HttpWebRequest;
            try
            {
                // if response == null, we'll get exception
                // ReSharper disable once PossibleNullReferenceException
                WebResponse response = request.EndGetResponse(result);
                string resultText = GetUtf8TextFromWebResponse(response);
                CallbackStruct callback = this._callbacks.SafeGet(request);
                this._callbacks.SafeRemove(request);
                if (resultText.IndexOf(SDK.ResponsePartErrorCode + ":" + SDK.ErrorCodeSessionExpired, System.StringComparison.OrdinalIgnoreCase) != -1)
                {
                    if (callback.OnError != null)
                    {
                        callback.OnError(new Exception(ErrorSessionExpired));
                        return;
                    }
                }
                else if (resultText.IndexOf(SDK.ResponsePartErrorCode, System.StringComparison.OrdinalIgnoreCase) != -1)
                {
                    if (callback.OnError != null)
                    {
                        callback.OnError(new Exception(ErrorBadApiRequest + "  " + resultText));
                        return;
                    }
                }
                if (callback.CallbackContext != null && callback.OnSuccess != null)
                {
                    callback.CallbackContext.Dispatcher.BeginInvoke(() => callback.OnSuccess.Invoke(resultText));
                }    
            }
            catch (WebException e)
            {
                Action<Exception> onError = this._callbacks.SafeGet(request).OnError;
                this._callbacks.SafeRemove(request);
                if (onError != null)
                {
                    onError.Invoke(e);
                }
            }
        }

        private static string GetUtf8TextFromWebResponse(WebResponse response)
        {
            StringBuilder sb = new StringBuilder();
            Byte[] buf = new byte[8192];
            Stream resStream = response.GetResponseStream();
            int count;
            do
            {
                count = resStream.Read(buf, 0, buf.Length);
                if (count != 0)
                {
                    sb.Append(Encoding.UTF8.GetString(buf, 0, count));
                }
            } while (count > 0);
            return sb.ToString();
        }

        /// <summary>
        /// Calculates signature for API request with given method and parameters.
        /// </summary>
        /// <param name="method">method name</param>
        /// <param name="parameters">dictionary "parameter_name":"parameter_value"</param>
        /// <returns>Returns signature.</returns>
        private string CalcSignature(string method, Dictionary<string, string> parameters = null)
        {
            Dictionary<string, string> parametersLocal = parameters == null ? new Dictionary<string, string>() : new Dictionary<string, string>(parameters);

            parametersLocal.Add("application_key", this._appPublicKey);
            parametersLocal.Add("method", method);
            StringBuilder builder = new StringBuilder();
            foreach (KeyValuePair<string, string> pair in parametersLocal.OrderBy(item=>item.Key))
            {
                builder.Append(pair.Key).Append("=").Append(pair.Value);
            }
            string s = MD5.GetMd5String(this._accessToken.Insert(this._accessToken.Length, this._appSecretKey));
            return MD5.GetMd5String(builder.Append(s).ToString());
        }


    }
}
