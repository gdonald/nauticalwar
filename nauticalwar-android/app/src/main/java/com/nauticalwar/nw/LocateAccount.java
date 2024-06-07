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

public class LocateAccount extends Activity
{
  private static final int MENU_GO_LOGIN = 0;

  private EditText email;
  private final Handler handler = new Handler();
  private MyApplication app;
  private String results;

  private WaitDialog waitDialogLocatingAccount;

  private final OnClickListener locateAccountClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      locateAccountBegin();
    }
  };

  private final Runnable updateLocatingAccountResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogLocatingAccount.dismiss();
      updateLocateAccountUi();
    }
  };

  private void goLogin()
  {
    Intent i = new Intent(this, Login.class);
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
    setContentView(R.layout.locate_account);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    email = findViewById(R.id.email);

    Button locate = findViewById(R.id.locate);
    locate.setSoundEffectsEnabled(false);
    locate.setOnClickListener(locateAccountClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.locating_account));
    waitDialogLocatingAccount = new WaitDialog();
    waitDialogLocatingAccount.setArguments(args);
  }

  @Override
  public boolean onCreateOptionsMenu(final Menu menu)
  {
    boolean result = super.onCreateOptionsMenu(menu);
    menu.add(0, LocateAccount.MENU_GO_LOGIN, 0, "Login").setIcon(R.drawable.ic_menu_forward);
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
      goLogin();
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

  private String postLocateAccount()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/players/locate_account";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("email", email.getText().toString()));
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

  private void locateAccountBegin()
  {
    waitDialogLocatingAccount.show(getFragmentManager(), "locating_account");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postLocateAccount();
        handler.post(updateLocatingAccountResults);
      }
    }.start();
  }

  private void updateLocateAccountUi()
  {
    JSONObject o;
    JSONObject errors;
    JSONArray errors_email;
    String error_email;

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
      app.toast(LocateAccount.this, "Server down..");
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
          app.toast(LocateAccount.this, "Email " + error_email);
          return;
        }
      }
    }

    int playerID = 0;

    try
    {
      playerID = o.getInt("id");
    }
    catch( JSONException e )
    {
      playerID = 0;
    }

    if( playerID > 0 )
    {
      app.toastLong(LocateAccount.this, "Account found, check your email");

      goLogin();
      return;
    }

    app.toastLong(LocateAccount.this, "Account not found");
    goLogin();
  }
}
