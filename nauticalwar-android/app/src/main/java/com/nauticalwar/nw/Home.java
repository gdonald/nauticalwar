package com.nauticalwar.nw;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;

import com.nauticalwar.shared.MyApplication;
import com.nauticalwar.shared.MyHTTP;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class Home extends Activity
{
  private MyApplication app;
  private Button games;
  private String game_count_results, invite_count_results;
  private final Handler handler = new Handler();

  private Button invites;

  private final OnClickListener logoutClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      logoutBegin();
    }
  };

  private final OnClickListener optionsClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goOptions();
    }
  };

  private final OnClickListener gamesClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goCurrentGames();
    }
  };

  private final OnClickListener inviteClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goPlayers();
    }
  };

  private final OnClickListener currentInvitesClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goCurrentInvites();
    }
  };

  private final Runnable updateGamesCount = new Runnable()
  {
    @Override
    public void run()
    {
      updateGamesCountUi();
    }
  };

  private final Runnable updateInvitesCount = new Runnable()
  {
    @Override
    public void run()
    {
      updateInvitesCountUi();
    }
  };

  private final Runnable getInvitesCount = new Runnable()
  {
    @Override
    public void run()
    {
      getInvitesCount();
    }
  };

  private final Runnable getGamesCount = new Runnable()
  {
    @Override
    public void run()
    {
      getGamesCount();
    }
  };

  private void checkIfLoggedIn()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        try
        {
          if( app.needToLogin() )
          {
            goLogin();
          }
          else
          {
            handler.post(getGamesCount);
            handler.post(getInvitesCount);
          }
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  private void getGamesCount()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        game_count_results = app.getGamesCount();
        handler.post(updateGamesCount);
      }
    }.start();
  }

  private void getInvitesCount()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        invite_count_results = app.getInvitesCount();
        handler.post(updateInvitesCount);
      }
    }.start();
  }

  private void goCurrentGames()
  {
    Intent i = new Intent(this, Games.class);
    startActivity(i);
    finish();
  }

  private void goCurrentInvites()
  {
    Intent i = new Intent(this, Invites.class);
    startActivity(i);
    finish();
  }

  private void goLogin()
  {
    app.toast(Home.this, "Your session has expired, please login");

    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goOptions()
  {
    Intent i = new Intent(this, Options.class);
    startActivity(i);
    finish();
  }

  private void goPlayers()
  {
    Intent i = new Intent(this, Players.class);
    startActivity(i);
    finish();
  }

  private void logoutBegin()
  {
    new AlertDialog.Builder(Home.this).setMessage("Are you sure you want to logout?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
    {
      @Override
      public void onClick(final DialogInterface dialog, final int id)
      {
        app.sndClick();
        dialog.cancel();
      }
    }).setPositiveButton("Yes", new DialogInterface.OnClickListener()
    {
      @Override
      public void onClick(final DialogInterface dialog, final int id)
      {
        app.sndClick();
        dialog.cancel();
        startLogout();
      }
    }).show();
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.home);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    games = findViewById(R.id.games);
    games.setSoundEffectsEnabled(false);
    games.setOnClickListener(gamesClickListener);

    Button invite = findViewById(R.id.invite);
    invite.setSoundEffectsEnabled(false);
    invite.setOnClickListener(inviteClickListener);

    invites = findViewById(R.id.invites);
    invites.setSoundEffectsEnabled(false);
    invites.setOnClickListener(currentInvitesClickListener);

    Button logout = findViewById(R.id.logout);
    logout.setSoundEffectsEnabled(false);
    logout.setOnClickListener(logoutClickListener);

    Button options = findViewById(R.id.options);
    options.setSoundEffectsEnabled(false);
    options.setOnClickListener(optionsClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    checkIfLoggedIn();
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
    return keyCode == KeyEvent.KEYCODE_BACK || super.onKeyDown(keyCode, event);
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

  private void startLogout()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        try
        {
          boolean doNotify = app.getSettings().getBoolean("doNotify", false);

          if( !doNotify )
          {
            BasicCookieStore cookieStore = app.getDB().populateCookies();
            MyHTTP http = new MyHTTP(cookieStore);

            List< NameValuePair > params = new ArrayList<>();
            params.add(new BasicNameValuePair("_method", "delete"));
            params.add(new BasicNameValuePair("format", "json"));

            http.doPost(app.getBaseURL() + "/api/sessions", params);

            app.getDB().open();
            app.getDB().saveCookies(null);
            app.getDB().close();
          }

          finish();
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  private void updateGamesCountUi()
  {
    JSONObject o;
    int count = 0;

    try
    {
      o = new JSONObject(game_count_results);
    }
    catch( JSONException e )
    {
      o = null;
    }

    if( o != null )
    {
      try
      {
        count = o.getInt("count");
      }
      catch( JSONException e )
      {
        e.printStackTrace();
      }
    }

    games.setText(getString(R.string.games_count, count));
  }

  private void updateInvitesCountUi()
  {
    JSONObject o;
    int count = 0;

    try
    {
      o = new JSONObject(invite_count_results);
    }
    catch( JSONException e )
    {
      o = null;
    }

    if( o != null )
    {
      try
      {
        count = o.getInt("count");
      }
      catch( JSONException e )
      {
        e.printStackTrace();
      }
    }

    invites.setText(getString(R.string.invites_count, count));
  }
}
