package com.nauticalwar.nw;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.MyApplication;

import com.google.android.gms.tasks.Task;
import com.nauticalwar.shared.MyHTTP;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class Splash extends Activity
{
  private MyApplication app;
  private GoogleSignInClient mGoogleSignInClient;
  private int RC_SIGN_IN = 1;

  private WaitDialog waitDialogCheckGoogleAccountExists;
  private String results;
  private String googleEmail;

  private final Handler handler = new Handler();

  private final OnClickListener googleClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      Intent signInIntent = mGoogleSignInClient.getSignInIntent();
      startActivityForResult(signInIntent, RC_SIGN_IN);
    }
  };

  private final OnClickListener loginClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goLogin();
    }
  };

  private final OnClickListener signupClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goSignup();
    }
  };

  private void goLogin()
  {
    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goSignup()
  {
    Intent i = new Intent(this, Signup.class);
    startActivity(i);
    finish();
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
    startActivity(i);
    finish();
  }

  private void goCompleteGoogleSignup()
  {
    Intent i = new Intent(this, CompleteGoogleSignup.class);
    i.putExtra("email", googleEmail);
    startActivity(i);
    finish();
  }

  private String postCheckGoogleAccountExists()
  {
    BasicCookieStore bcs = new BasicCookieStore();
    MyHTTP http = new MyHTTP(bcs);
    String url = getString(R.string.base_url) + "/api/players/account_exists";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("email", googleEmail));
    params.add(new BasicNameValuePair("format", "json"));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(bcs);
    app.saveLoginCookie(bcs);

    return s;
  }

  private void googleSignInSuccess(GoogleSignInAccount account)
  {
    googleEmail = account.getEmail();
    waitDialogCheckGoogleAccountExists.show(getFragmentManager(), "check_google_account_exists");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postCheckGoogleAccountExists();
        handler.post(updateCheckGoogleAccountExistsResults);
      }
    }.start();
  }

  private final Runnable updateCheckGoogleAccountExistsResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogCheckGoogleAccountExists.dismiss();
      updateCheckGoogleAccountExistsUi();
    }
  };

  private void updateCheckGoogleAccountExistsUi()
  {
    JSONObject o;
    int player_id;

    if( results == null )
    {
      app.toast(Splash.this, "Server down");
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
      app.toast(Splash.this, "Please confirm username");
      goCompleteGoogleSignup();
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

      app.toast(Splash.this, "Login complete");
      goHome();
      return;
    }

    app.toast(Splash.this, "Unknown error");
  }

  private void handleGoogleSignInResult(Task<GoogleSignInAccount> completedTask)
  {
    try
    {
      GoogleSignInAccount account = completedTask.getResult(ApiException.class);
      googleSignInSuccess(account);
    }
    catch (ApiException e)
    {
      e.printStackTrace();
    }
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.splash);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();

    DisplayMetrics displaymetrics = new DisplayMetrics();
    getWindowManager().getDefaultDisplay().getMetrics(displaymetrics);
    app.setDefaultWidth(displaymetrics.widthPixels);

    Button login = findViewById(R.id.login);
    login.setOnClickListener(loginClickListener);
    login.setSoundEffectsEnabled(false);

    Button signup = findViewById(R.id.signup);
    signup.setOnClickListener(signupClickListener);
    signup.setSoundEffectsEnabled(false);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackgroundResource(app.getWater());

    GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).requestEmail().build();
    mGoogleSignInClient = GoogleSignIn.getClient(this, gso);

//    findViewById(R.id.sign_in_button).setOnClickListener(googleClickListener);

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.checking_account));
    waitDialogCheckGoogleAccountExists = new WaitDialog();
    waitDialogCheckGoogleAccountExists.setArguments(args);
  }

  @Override
  protected void onStart()
  {
    super.onStart();
    // GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data)
  {
    super.onActivityResult(requestCode, resultCode, data);

    if (requestCode == RC_SIGN_IN)
    {
      Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
      handleGoogleSignInResult(task);
    }
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
      finish();
      return true;
    }

    return super.onKeyDown(keyCode, event);
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
}
