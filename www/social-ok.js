function SocialOk() {
  // Does nothing
}
SocialOk.prototype.init = function(appId, secret, key, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "initSocialOk", [appId, secret, key]);
};

SocialOk.prototype.login = function(permissions, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "login", [permissions]);
};

SocialOk.prototype.share = function(sourceURL, description, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "share", [sourceURL, description]);
};

SocialOk.prototype.friendsGet = function(fid, sort_type, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "friendsGet", [fid, sort_type]);
};

SocialOk.prototype.friendsGetOnline = function(uid, online, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "friendsGetOnline", [uid, online]);
};

SocialOk.prototype.streamPublish = function(attachments, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "streamPublish", [attachments]);
};

SocialOk.prototype.usersGetInfo = function(uids, fields, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "usersGetInfo", [uids, fields]);
};

SocialOk.prototype.callApiMethod = function(method, params, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "callApiMethod", [method, params]);
};

SocialOk.prototype.isOkAppInstalled = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "isOkAppInstalled", []);
};

SocialOk.prototype.reportPayment = function(trx_id, amount, currency, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "reportPayment", [trx_id, amount, currency]);
};

module.exports = new SocialOk();
