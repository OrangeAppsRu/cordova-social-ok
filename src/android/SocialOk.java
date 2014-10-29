package ru.trilan.googleplus;

import org.json.JSONException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;

import android.content.Context;
import android.util.Log;

public class SocialOk extends CordovaPlugin {
  public static final String TAG = "SocialOk";
  public static final String INIT = "initSocialOk";

  /**
   * Gets the application context from cordova's main activity.
   * @return the application context
   */
  private Context getApplicationContext() {
    return this.webView.getContext();
  }
	
  @Override
  public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
    boolean result = false;
    final String sourceUrl, imageUrl, description;
    //callbackContext.success();
    callbackContext.error("Not implemented");

    return result;
  }
}
