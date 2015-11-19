using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using Windows.ApplicationModel.Store;
using WPCordovaClassLib.Cordova;
using WPCordovaClassLib.Cordova.Commands;
using WPCordovaClassLib.Cordova.JSON;
using Odnoklassniki;

namespace WPCordovaClassLib.Cordova.Commands
{

    public class SocialOk : BaseCommand
    {
        private readonly SDK _sdk;
        private const string Permissions = "VALUABLE_ACCESS";

        public void initSocialOk(string appId, string secret, string key) {
            this._sdk = new SDK(appId, key, secret, RedirectUrl, Permissions);
        }

        public void login(string permissions) {
            if (this._sdk.TryLoadSession() == false) {
                //this.Browser.Visibility = Visibility.Visible;
                this._sdk.Authorize(Browser, this, AuthCallback, ErrorCallback);
            } else {
                this.AuthCallback();
            }
        }

        public void share(string sourceUrl, string description) {
            System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string> {
                { "linkUrl", sourceUrl },
                { "comment", description }
            };
            this._sdk.SendRequest("share.addLink", parameters, this, CommonApiCallback, ErrorCallback);
            
        }

        public void friendsGet(string fid, string sort_type) {
            System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string> {
                { "fid", fid },
                { "sort_type", sort_type }
            };
            this._sdk.SendRequest("friends.get", parameters, this, CommonApiCallback, ErrorCallback);
        }

        public void friendsGetOnline(string uid, string online) {
            System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string> {
                { "uid", uid },
                { "online", online }
            };
            this._sdk.SendRequest("friends.getOnline", parameters, this, CommonApiCallback, ErrorCallback);
        }

        public void streamPublish(string attachments) {
            ErrorCallback(new Exception("Feature not implemented yet!"));
        }

        public void usersGetInfo(string uids, string fields) {
            System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string> {
                { "uids", uids },
                { "fields", fields }
            };
            this._sdk.SendRequest("users.getInfo", parameters, this, CommonApiCallback, ErrorCallback);
        }

        public void callApiMethod(string method, System.Collections.Generic.Dictionary<string, string> parameters) {
            this._sdk.SendRequest("users.getCurrentUser", parameters, this, CommonApiCallback, ErrorCallback);
        }

        private void CommonApiCallback( string result) {
            JObject resObject = JObject.Parse(result);
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK, resObject));
        }

        // uses users.getCurrentUser to get info about authorized user: first name, last name, location and photo 128*128 url
        private void AuthCallback()
        {
            //this.Browser.Visibility = Visibility.Collapsed;
            System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string>
                {
                    {"fields", "first_name,last_name,location,pic_5"}
                };
            this._sdk.SendRequest("users.getCurrentUser", parameters, this, GetCurrentUserCallback, ErrorCallback);
        }

        // downloads and sets user photo and one friend's name
        void GetCurrentUserCallback(string result)
        {
            JObject resObject = JObject.Parse(result);
            DispatchCommandResult(new PluginResult(PluginResult.Status.OK, resObject));
            /*
            this.NameField.Text = (string)resObject["first_name"];
            this.SurnameField.Text = (string)resObject["last_name"];
            Utils.DownloadImageAsync(new Uri((string)resObject["pic_5"]), this, i => {
                    this.UserPhotoImage.Source = i;
                }, ErrorCallback);
            this._sdk.SendRequest("friends.get", null, this, friendsList => {
                    JArray friendsArray = JArray.Parse(friendsList);
                    System.Collections.Generic.Dictionary<string, string> parameters = new System.Collections.Generic.Dictionary<string, string> {
                        {"uids", friendsArray[0].ToString()},
                        {"fields", "first_name,last_name"}
                    };
                    this._sdk.SendRequest("users.getInfo", parameters, this, randomFriend => {
                            JArray randomFriendObj = JArray.Parse(randomFriend);
                            this.RandomFriendNameLabel.Text = randomFriendObj[0]["first_name"].ToString() + " " + randomFriendObj[0]["last_name"].ToString();
                            this.RandomFriendLabel.Visibility = Visibility.Visible;
                            this.RandomFriendNameLabel.Visibility = Visibility.Visible;
                        }, ErrorCallback);
                }, ErrorCallback);
            */
        }

        // prints debug error message to stdout
        private void ErrorCallback(Exception e)
        {
            System.Diagnostics.Debug.WriteLine("Exception: " + e);
            DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR, e.Message));
            if (e.Message != SDK.ErrorSessionExpired) return;
            System.Diagnostics.Debug.WriteLine("Session expired error caught. Trying to update session.");
            this._sdk.UpdateToken(this, AuthCallback, null);
        }
    }
}
