function SocialOk() {
  // Does nothing
}
SocialOk.prototype.init = function(appId, secret, key, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "SocialOk", "initSocialOk", [appId, secret, key]);
};

SocialOk.prototype.login = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "SocialOk", "login", []);
};

SocialOk.prototype.share = function(sourceURL, description, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "SocialOk", "share", [sourceURL, description]);
};

SocialOk.prototype.callApiMethod = function(method, params, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "SocialOk", "callApiMethod", [method, params]);
};

module.exports = new SocialOk();
