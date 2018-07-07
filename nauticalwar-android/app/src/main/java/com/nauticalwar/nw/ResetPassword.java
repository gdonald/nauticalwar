package com.nauticalwar.nw;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.MyApplication;
import com.nauticalwar.shared.MyHTTP;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class ResetPassword extends Activity
{
  private static final int MENU_GO_SIGNUP = 0;

  private final Handler handler = new Handler();
  private MyApplication app;
  private EditText password, passwordConfirmation;
  private String results, passwordToken;

  private WaitDialog waitDialogResetPassword;

  private final OnClickListener resetPasswordClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      resetPasswordBegin();
    }
  };

  private final Runnable updateResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogResetPassword.dismiss();
      updateUi();
    }
  };

  private void goLogin()
  {
    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goLocateAccount()
  {
    Intent i = new Intent(this, LocateAccount.class);
    startActivity(i);
    finish();
  }

  private void resetPasswordBegin()
  {
    waitDialogResetPassword.show(getFragmentManager(), "resetting_password");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postResetPassword();
        handler.post(updateResults);
      }
    }.start();
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.reset_password);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    DisplayMetrics displaymetrics = new DisplayMetrics();
    getWindowManager().getDefaultDisplay().getMetrics(displaymetrics);
    app.setDefaultWidth(displaymetrics.widthPixels);

    app.smallScreenHeaderFix(this);

    passwordConfirmation = findViewById(R.id.password_confirmation);
    password = findViewById(R.id.password);

    Button resetPassword = findViewById(R.id.reset_password);
    resetPassword.setOnClickListener(resetPasswordClickListener);
    resetPassword.setSoundEffectsEnabled(false);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.resetting_password));
    waitDialogResetPassword = new WaitDialog();
    waitDialogResetPassword.setArguments(args);

    Bundle extras = getIntent().getExtras();
    if(extras != null)
    {
      passwordToken = extras.getString("passwordToken");
    }
  }

  @Override
  public boolean onCreateOptionsMenu(final Menu menu)
  {
    boolean result = super.onCreateOptionsMenu(menu);
    menu.add(0, ResetPassword.MENU_GO_SIGNUP, 0, "Signup").setIcon(R.drawable.ic_menu_forward);
    return result;
  }

  @Override
  protected void onDestroy()
  {
    super.onDestroy();
    app.unbindDrawables(findViewById(R.id.outer));
  }

  @Override
  public boolean onKeyDown(final int keyCode, final KeyEvent event)
  {
    if(keyCode == KeyEvent.KEYCODE_BACK)
    {
      goLogin();
      return true;
    }

    return super.onKeyDown(keyCode, event);
  }

  @Override
  public boolean onOptionsItemSelected(final MenuItem item)
  {
    app.sndClick();

    switch(item.getItemId())
    {
      case MENU_GO_SIGNUP:
        goLogin();
        return true;
    }

    return false;
  }

  @Override
  protected void onPause()
  {
    super.onPause();
    app.setPaused(true);
    app.unMuteSystemSound();
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    app.setPaused(false);
    app.muteSystemSound();
  }

  private String postResetPassword()
  {
    String pwd = password.getText().toString();
    String pwd2 = passwordConfirmation.getText().toString();

    if(!(pwd.length() == pwd2.length() && pwd.contains(pwd2)))
    {
      app.toast(ResetPassword.this, "Password confirmation does not match");
      return null;
    }

    if(pwd.length() == 0)
    {
      app.toast(ResetPassword.this, "Password required");
      return null;
    }

    if(pwd2.length() == 0)
    {
      app.toast(ResetPassword.this, "Password confirmation required");
      return null;
    }

    BasicCookieStore bcs = new BasicCookieStore();
    MyHTTP http = new MyHTTP(bcs);
    String url = getString(R.string.base_url) + "/api/players/reset_password";

    List<NameValuePair> params = new ArrayList<>();
    params.add(new BasicNameValuePair("token", passwordToken));
    params.add(new BasicNameValuePair("password", password.getText().toString()));
    params.add(new BasicNameValuePair("password_confirmation", passwordConfirmation.getText().toString()));
    params.add(new BasicNameValuePair("format", "json"));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(bcs);
    app.saveLoginCookie(bcs);

    return s;
  }

  private void updateUi()
  {
    JSONObject o;
    String error;
    int player_id;

    if(results == null)
    {
      app.toast(ResetPassword.this, "Server down");
      return;
    }

    try
    {
      o = new JSONObject(results);
    }
    catch(JSONException e)
    {
      e.printStackTrace();
      o = null;
    }

    if(o == null)
    {
      app.toast(ResetPassword.this, "Cannot parse response");
      return;
    }

    try
    {
      error = o.getString("error");
    }
    catch(JSONException e)
    {
      error = null;
    }

    if(error != null)
    {
      app.toast(ResetPassword.this, error);
      return;
    }

    try
    {
      player_id = o.getInt("id");
    }
    catch(JSONException e)
    {
      player_id = 0;
    }

    if(player_id == -1)
    {
      app.toast(ResetPassword.this, "Password token has expired");

      goLocateAccount();
      return;
    }

    if(player_id > 0)
    {
      app.toast(ResetPassword.this, "Password reset, please login");

      goLogin();
      return;
    }

    app.toast(ResetPassword.this, "Unknown error");
  }
}
