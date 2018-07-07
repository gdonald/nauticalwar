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
import android.widget.CheckBox;
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

public class Login extends Activity
{
  private static final int MENU_GO_SIGNUP = 0;

  private EditText email;
  private final Handler handler = new Handler();
  private MyApplication app;
  private EditText password;
  private CheckBox remember_login;
  private String results, passwordToken;

  private WaitDialog waitDialogLoggingIn;

  private final OnClickListener loginClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      loginBegin();
    }
  };

  private final OnClickListener resetPasswordClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goLocateAccount();
    }
  };

  private final Runnable updateResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogLoggingIn.dismiss();
      updateUi();
    }
  };

  private void goLocateAccount()
  {
    Intent i = new Intent(this, LocateAccount.class);
    startActivity(i);
    finish();
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
    startActivity(i);
    finish();
  }

  private void goSignup()
  {
    Intent i = new Intent(this, Signup.class);
    startActivity(i);
    finish();
  }

  private void goSplash()
  {
    Intent i = new Intent(this, Splash.class);
    startActivity(i);
    finish();
  }

  private void goResetPassword()
  {
    Intent i = new Intent(this, ResetPassword.class);
    i.putExtra("passwordToken", passwordToken);
    startActivity(i);
    finish();
  }

  private void loginBegin()
  {
    waitDialogLoggingIn.show(getFragmentManager(), "logging_in");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postLogin();
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
    setContentView(R.layout.login);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    remember_login = findViewById(R.id.remember_login);
    remember_login.setSoundEffectsEnabled(false);

    email = findViewById(R.id.email);
    password = findViewById(R.id.password);

    if( app.getSettings().getBoolean("remember_login", false) )
    {
      remember_login.setChecked(true);
      email.setText(app.getSettings().getString("email", ""));
      password.setText(app.getSettings().getString("password", ""));
    }

    Button login = findViewById(R.id.login);
    login.setOnClickListener(loginClickListener);
    login.setSoundEffectsEnabled(false);

    Button resetPassword = findViewById(R.id.reset_password);
    resetPassword.setOnClickListener(resetPasswordClickListener);
    resetPassword.setSoundEffectsEnabled(false);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.logging_in));
    waitDialogLoggingIn = new WaitDialog();
    waitDialogLoggingIn.setArguments(args);

    Intent intent = getIntent();
    if (Intent.ACTION_VIEW.equals(intent.getAction()))
    {
      passwordToken = intent.getData().getQueryParameter("token");

      if(passwordToken != null)
      {
        goResetPassword();
      }
    }
  }

  @Override
  public boolean onCreateOptionsMenu(final Menu menu)
  {
    boolean result = super.onCreateOptionsMenu(menu);
    menu.add(0, Login.MENU_GO_SIGNUP, 0, "Signup").setIcon(R.drawable.ic_menu_forward);
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
      case MENU_GO_SIGNUP:
        goSignup();
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

  private String postLogin()
  {
    BasicCookieStore bcs = new BasicCookieStore();
    MyHTTP http = new MyHTTP(bcs);
    String url = getString(R.string.base_url) + "/api/sessions";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("email", email.getText().toString()));
    params.add(new BasicNameValuePair("password", password.getText().toString()));
//    params.add(new BasicNameValuePair("format", "json"));

    if( remember_login.isChecked() )
    {
      app.getSettings().edit().putBoolean("remember_login", true).apply();
      app.getSettings().edit().putString("email", email.getText().toString().trim()).apply();
      app.getSettings().edit().putString("password", password.getText().toString().trim()).apply();
    }
    else
    {
      app.getSettings().edit().putBoolean("remember_login", false).apply();
      app.getSettings().edit().putString("email", null).apply();
      app.getSettings().edit().putString("password", null).apply();
    }

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

    if( results == null )
    {
      app.toast(Login.this, "Server down");
      return;
    }

    try
    {
      o = new JSONObject(results);
    }
    catch( JSONException e )
    {
      e.printStackTrace();
      o = null;
    }

    if( o == null )
    {
      app.toast(Login.this, "Cannot parse response");
      return;
    }

    try
    {
      error = o.getString("error");
    }
    catch( JSONException e )
    {
      error = null;
    }

    if( error != null )
    {
      app.toast(Login.this, error);
      return;
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

      goHome();
      return;
    }

    app.toast(Login.this, "unknown error");
  }
}
