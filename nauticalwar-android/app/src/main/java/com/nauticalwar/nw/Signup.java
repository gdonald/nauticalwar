package com.nauticalwar.nw;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
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
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class Signup extends Activity
{
  private static final int MENU_GO_LOGIN = 0;

  private EditText name;
  private EditText email;
  private final Handler handler = new Handler();
  private MyApplication app;
  private EditText password;
  private String results;

  private WaitDialog waitDialogSigningUp;

  private final OnClickListener signupClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      signupBegin();
    }
  };

  private final Runnable updateSigningUpResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogSigningUp.dismiss();
      updateSigningUpUi();
    }
  };

  private void goLogin()
  {
    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goSplash()
  {
    Intent i = new Intent(this, Splash.class);
    startActivity(i);
    finish();
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.signup);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    name = findViewById(R.id.name);
    email = findViewById(R.id.email);
    password = findViewById(R.id.password);

    Button signup = findViewById(R.id.signup);
    signup.setSoundEffectsEnabled(false);
    signup.setOnClickListener(signupClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.signing_up));
    waitDialogSigningUp = new WaitDialog();
    waitDialogSigningUp.setArguments(args);
  }

  @Override
  public boolean onCreateOptionsMenu(final Menu menu)
  {
    boolean result = super.onCreateOptionsMenu(menu);
    menu.add(0, Signup.MENU_GO_LOGIN, 0, "Login").setIcon(R.drawable.ic_menu_forward);
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
    if( keyCode == KeyEvent.KEYCODE_BACK )
    {
      goSplash();
      return true;
    }

    return super.onKeyDown(keyCode, event);
  }

  @Override
  public boolean onOptionsItemSelected(final MenuItem item)
  {
    app.sndClick();

    switch( item.getItemId() )
    {
      case MENU_GO_LOGIN:
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

  private String postSignup()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/players";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("name", name.getText().toString()));
    params.add(new BasicNameValuePair("email", email.getText().toString()));
    params.add(new BasicNameValuePair("password", password.getText().toString()));
    params.add(new BasicNameValuePair("password_confirmation", password.getText().toString()));
    params.add(new BasicNameValuePair("format", "json"));

    String s;

    try
    {
      s = http.doPost(url, params).trim();
    }
    catch( Exception e )
    {
      s = null;
    }

    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void signupBegin()
  {
    waitDialogSigningUp.show(getFragmentManager(), "signing_up");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postSignup();
        handler.post(updateSigningUpResults);
      }
    }.start();
  }

  private void updateSigningUpUi()
  {
    JSONObject o;
    JSONObject errors;
    JSONArray errors_email;
    JSONArray errors_name;
    String error_email;
    String error_name;
    int player_id;

    try
    {
      o = new JSONObject(results);
    }
    catch( JSONException e )
    {
      o = null;
    }

    if( o == null )
    {
      app.toast(Signup.this, "Server down..");
      return;
    }

    try
    {
      errors = o.getJSONObject("errors");
    }
    catch( JSONException e )
    {
      errors = null;
    }

    if( errors != null )
    {
      try
      {
        errors_email = errors.getJSONArray("email");
      }
      catch( JSONException e )
      {
        errors_email = null;
      }

      if( errors_email != null )
      {
        try
        {
          error_email = errors_email.getString(0);
        }
        catch( JSONException e )
        {
          error_email = null;
        }

        if( error_email != null )
        {
          app.toast(Signup.this, "Email " + error_email);
          return;
        }
      }

      try
      {
        errors_name = errors.getJSONArray("name");
      }
      catch( JSONException e )
      {
        errors_name = null;
      }

      if( errors_name != null )
      {
        try
        {
          error_name = errors_name.getString(0);
        }
        catch( JSONException e )
        {
          error_name = null;
        }

        if( error_name != null )
        {
          app.toast(Signup.this, "Name " + error_name);
          return;
        }
      }
    }

    try
    {
      player_id = o.getInt("id");
    }
    catch( JSONException e )
    {
      player_id = 0;
    }

    if( player_id != 0 )
    {
      app.getSettings().edit().putInt("player_id", player_id).apply();
      app.toastLong(Signup.this, "Check your email to complete the signup");

      goLogin();
      return;
    }

    app.toast(Signup.this, "unknown error");
  }
}
