function SocialOk() {
  // Does nothing
}
SocialOk.prototype.init = function(appId, secret, key, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "initSocialOk", [appId, key]);
};

SocialOk.prototype.login = function(permissions, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "login", [permissions]);
};

SocialOk.prototype.logout = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "logout", []);
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
    amount = String(amount);
    amount = amount.replace(",", ".");
    cordova.exec(successCallback, errorCallback, "SocialOk", "reportPayment", [trx_id, amount, currency]);
};

SocialOk.prototype.getInstallSource = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "getInstallSource", []);
};

SocialOk.prototype.performPosting = function(params, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "performPosting", [params]);
};

SocialOk.prototype.performSuggest = function(params, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "performSuggest", [params]);
};

SocialOk.prototype.performInvite = function(params, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "performInvite", [params]);
};

SocialOk.prototype.reportStats = function(params, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "reportStats", [params]);
};

SocialOk.prototype.version = 10100;

module.exports = new SocialOk();
