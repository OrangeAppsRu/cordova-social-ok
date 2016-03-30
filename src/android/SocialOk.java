package ru.trilan.socialok;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

import android.content.Intent;
import android.content.Context;
import android.widget.Toast;
import android.util.Log;
import android.os.AsyncTask;
import java.util.HashMap;
import java.util.Map;
import java.io.IOException;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;

import ru.ok.android.sdk.Odnoklassniki;
import ru.ok.android.sdk.OkListener;
import ru.ok.android.sdk.util.OkScope;
import ru.ok.android.sdk.util.OkDevice;
import ru.ok.android.sdk.util.OkAuthType;

public class SocialOk extends CordovaPlugin {
    private static final String TAG = "SocialOk";
    private static final String ACTION_INIT = "initSocialOk";
    private static final String ACTION_LOGIN = "login";
    private static final String ACTION_SHARE = "share";
    private static final String ACTION_FRIENDS_GET = "friendsGet";
    private static final String ACTION_FRIENDS_GET_ONLINE = "friendsGetOnline";
    private static final String ACTION_STREAM_PUBLISH = "streamPublish";
    private static final String ACTION_USERS_GET_INFO = "usersGetInfo";
    private static final String ACTION_CALL_API_METHOD = "callApiMethod";
    private static final String ACTION_REPORT_PAYMENT = "reportPayment";
    private static final String ACTION_INSTALL_SOURCE = "getInstallSource";
    private static final String IS_OK_APP_INSTALLED = "isOkAppInstalled";
    private Odnoklassniki odnoklassnikiObject;
    private CallbackContext _callbackContext;
    private String REDIRECT_URL = "";

    private static final String ODKL_APP_SIGNATURE = "3082025b308201c4a00302010202044f6760f9300d06092a864886f70d01010505003071310c300a06035504061303727573310c300a06035504081303737062310c300a0603550407130373706231163014060355040a130d4f646e6f6b6c6173736e696b6931143012060355040b130b6d6f62696c65207465616d311730150603550403130e416e647265792041736c616d6f763020170d3132303331393136333831375a180f32303636313232313136333831375a3071310c300a06035504061303727573310c300a06035504081303737062310c300a0603550407130373706231163014060355040a130d4f646e6f6b6c6173736e696b6931143012060355040b130b6d6f62696c65207465616d311730150603550403130e416e647265792041736c616d6f7630819f300d06092a864886f70d010101050003818d003081890281810080bea15bf578b898805dfd26346b2fbb662889cd6aba3f8e53b5b27c43a984eeec9a5d21f6f11667d987b77653f4a9651e20b94ff10594f76a93a6a36e6a42f4d851847cf1da8d61825ce020b7020cd1bc2eb435b0d416908be9393516ca1976ff736733c1d48ff17cd57f21ad49e05fc99384273efc5546e4e53c5e9f391c430203010001300d06092a864886f70d0101050500038181007d884df69a9748eabbdcfe55f07360433b23606d3b9d4bca03109c3ffb80fccb7809dfcbfd5a466347f1daf036fbbf1521754c2d1d999f9cbc66b884561e8201459aa414677e411e66360c3840ca4727da77f6f042f2c011464e99f34ba7df8b4bceb4fa8231f1d346f4063f7ba0e887918775879e619786728a8078c76647ed";


    /**
     * Gets the application context from cordova's main activity.
     * @return the application context
     */
    private Context getApplicationContext() {
        return this.webView.getContext();
    }
	
    @Override
    public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        this._callbackContext = callbackContext;
        if(ACTION_INIT.equals(action)) {
            return init(args.getString(0), args.getString(1), args.getString(2));
        } else if (ACTION_LOGIN.equals(action)) {
            JSONArray permissions = args.optJSONArray(0);
            return login(permissions, callbackContext);
        } else if (ACTION_SHARE.equals(action)) {
            return shareOrLogin(args.getString(0), args.getString(1));
        } else if (ACTION_FRIENDS_GET.equals(action)) {
            return friendsGet(args.getString(0), args.getString(1), callbackContext);
        } else if (ACTION_FRIENDS_GET_ONLINE.equals(action)) {
            return friendsGetOnline(args.getString(0), args.getString(1), callbackContext);
        } else if (ACTION_STREAM_PUBLISH.equals(action)) {
            // TODO
        } else if (ACTION_USERS_GET_INFO.equals(action)) {
            return usersGetInfo(args.getString(0), args.getString(1), callbackContext);
        } else if (ACTION_CALL_API_METHOD.equals(action)) {
            String method = args.getString(0);
            JSONObject params = args.getJSONObject(1);
            return callApiMethod(method, JsonHelper.toMap(params), callbackContext);
        } else if (ACTION_REPORT_PAYMENT.equals(action)) {
            String trx_id = args.getString(0);
            String amount = args.getString(1);
            String currency = args.getString(2);
            Map<String, String> params = new HashMap<String, String>();
            params.put("trx_id", trx_id);
            params.put("amount", amount);
            params.put("currency", currency);
            return callApiMethod("sdk.reportPayment", params, callbackContext);
        } else if(ACTION_INSTALL_SOURCE.equals(action)) {
            Map<String, String> params = new HashMap<String, String>();
            params.put("adv_id", OkDevice.getAdvertisingId(webView.getContext()));
            return callApiMethod("sdk.getInstallSource", params, callbackContext);
        } else if (IS_OK_APP_INSTALLED.equals(action)) {
            // check if OK application installed
            boolean ssoAvailable = false;
            final Intent intent = new Intent();
            intent.setClassName("ru.ok.android", "ru.ok.android.external.LoginExternal");
            final ResolveInfo resolveInfo = getApplicationContext().getPackageManager().resolveActivity(intent, 0);
            if (resolveInfo != null) {
                try {
                    final PackageInfo packageInfo = getApplicationContext().getPackageManager().getPackageInfo(resolveInfo.activityInfo.packageName, PackageManager.GET_SIGNATURES);
                    for (final Signature signature : packageInfo.signatures) {
                        if (signature.toCharsString().equals(ODKL_APP_SIGNATURE)) {
                            ssoAvailable = true;
                        }
                    }
                } catch (NameNotFoundException exc) {
                }
            }
            if (ssoAvailable) {
                _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, "true"));
                _callbackContext.success();
            } else {
                _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, "false"));
                _callbackContext.success();
            }
            return true;
        }
        Log.e(TAG, "Unknown action: "+action);
        _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Unimplemented method: "+action));
        _callbackContext.error("Unimplemented method: "+action);
        return true;
    }

    private boolean init(String appId, String secret, String key)
    {
        REDIRECT_URL = "okauth://ok" + appId;
        odnoklassnikiObject = Odnoklassniki.createInstance(webView.getContext(), appId, secret, key);
        _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK));
        _callbackContext.success();
        return true;
    }
    
    private boolean login(final JSONArray permissions, final CallbackContext context) 
    {
        OkListener okListener = new OkListener() {
                @Override
                public void onSuccess(final JSONObject json) {
                    final String token = json.optString("access_token");
                    Log.i(TAG, "Odnoklassniki accessToken = " + token);
                    new AsyncTask<String, Void, String>() {
                        @Override protected String doInBackground(String... args) {
                            try {
                                return odnoklassnikiObject.request("users.getCurrentUser", null, "post");
                            } catch (IOException e) {
                                e.printStackTrace();
                                context.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "OK login error:" + e));
                                context.error("Error");
                            }
                            return null;
                        }
                        @Override protected void onPostExecute(String result) {
                            try {
                                JSONObject loginDetails = new JSONObject();
                                loginDetails.put("token", token);
                                loginDetails.put("user", new JSONObject(result));
                                context.sendPluginResult(new PluginResult(PluginResult.Status.OK, loginDetails.toString()));
                                context.success();
                            } catch (Exception e) {
                                String err = "OK login error: " + e;
                                Log.e(TAG, err);
                                context.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, err));
                                context.error(err);
                            }
                        }
                    }.execute();
                }
                @Override
                public void onError(String error) {
                    Log.i(TAG, "OK login error: "+error);
                    context.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "OK login error: "+error));
                    context.error("OK login error: "+error);
                }
            };
        //вызываем запрос авторизации. После OAuth будет вызван callback, определенный для объекта
        String perm = null;
        if(permissions != null && permissions.length() > 0)
            perm = permissions.toString();
        else
            perm = OkScope.VALUABLE_ACCESS;
        OkAuthType authType = OkAuthType.ANY;
        odnoklassnikiObject.requestAuthorization(okListener, REDIRECT_URL, authType, perm);
        return true;
    }

    private boolean shareOrLogin(final String url, final String comment)
    {
        //определяем callback на операции с получением токена
        OkListener okListener = new OkListener() {
                @Override
                public void onSuccess(final JSONObject json) {
                    final String token = json.optString("token");
                    Log.i(TAG, "Odnoklassniki accessToken = " + token);
                    if (token == null)
                        Toast.makeText(webView.getContext(), "Не удалось авторизоваться в приложении через \"Одноклассников\"."
                                       + "\nОшибка на сервере \"Одноклассников\".", Toast.LENGTH_LONG).show();
                    else
                        share(url, comment);
                }

                @Override
                public void onError(String error) {
                    Log.i(TAG, "Auth error");
                    Toast.makeText(webView.getContext(), "Ошибка во время авторизации в приложении через \"Одноклассников\".",
                                   Toast.LENGTH_LONG).show();
                }
            };
        //вызываем запрос авторизации. После OAuth будет вызван callback, определенный для объекта
        OkAuthType authType = OkAuthType.ANY;
        odnoklassnikiObject.requestAuthorization(okListener, REDIRECT_URL, authType, OkScope.VALUABLE_ACCESS);
        return true;
    }

    private boolean share(final String url, final String comment)
    {
        final Map<String, String> params = new HashMap<String, String>();
        params.put("linkUrl", url);
        params.put("comment", comment);
        new AsyncTask<String, Void, String>() {
            @Override protected String doInBackground(String... args) {
                try {
                    return odnoklassnikiObject.request("share.addLink", params, "get");
                } catch (IOException e) {
                    e.printStackTrace();
                    _callbackContext.error("Error");
                }
                return null;
            }
            @Override protected void onPostExecute(String result) {
                Log.i(TAG, "OK share result" + result);
                _callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, result));
                _callbackContext.success();
            }
        }.execute();
        return true;
    }

    private boolean friendsGet(final String fid, final String sort_type, final CallbackContext context)
    {
        Map<String, String> params = new HashMap<String, String>();
        params.put("fid", fid);
        params.put("sort_type", sort_type);
        return callApiMethod("friends.get", params, context);
    }

    private boolean friendsGetOnline(final String uid, final String online, final CallbackContext context)
    {
        Map<String, String> params = new HashMap<String, String>();
        params.put("uid", uid);
        params.put("online", online);
        return callApiMethod("friends.getOnline", params, context);
    }

    private boolean usersGetInfo(final String uids, final String fields, final CallbackContext context)
    {
        Map<String, String> params = new HashMap<String, String>();
        params.put("uids", uids);
        params.put("fields", fields);
        return callApiMethod("users.getInfo", params, context);
    }

    private boolean callApiMethod(final String method, final Map<String, String> params, final CallbackContext context) 
    {
        new AsyncTask<String, Void, String>() {
            @Override protected String doInBackground(String... args) {
                try {
                    return odnoklassnikiObject.request(method, params, "post");
                } catch (Exception e) {
                    context.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, e.toString()));
                    context.error("Error");
                }
                return null;
            }
            @Override protected void onPostExecute(String result) {
                context.sendPluginResult(new PluginResult(PluginResult.Status.OK, result));
                context.success();
            }
        }.execute();
        return true;
    }
}
