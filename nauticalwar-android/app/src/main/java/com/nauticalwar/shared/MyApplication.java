package com.nauticalwar.shared;

import android.app.Activity;
import android.app.Application;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.media.AudioManager;
import android.os.IBinder;
import android.os.Vibrator;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewManager;
import android.widget.AdapterView;
import android.widget.LinearLayout;
import android.widget.Toast;

import com.nauticalwar.nw.Game;
import com.nauticalwar.nw.Games;
import com.nauticalwar.nw.R;
import com.nauticalwar.srv.MyService;

import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.BasicCookieStore;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class MyApplication extends Application
{
  private static final int SND_CLICK = 0;
  private static final int SND_SPLASH = 1;
  private static final int SND_EXPLOSION = 2;
  private static final int SND_RELOAD = 3;

  private int defaultWidth;

  private Database db;

  private SharedPreferences settings;
  private SoundManager soundManager;
  private Vibrator vibrator;

  private BitmapDrawable crosshair_d;
  private BitmapDrawable shadow_red_d;
  private BitmapDrawable shadow_white_d;

  private BitmapDrawable ship_carrier_vertical;
  private BitmapDrawable ship_carrier_horizontal;
  private BitmapDrawable ship_battleship_vertical;
  private BitmapDrawable ship_battleship_horizontal;
  private BitmapDrawable ship_destroyer_vertical;
  private BitmapDrawable ship_destroyer_horizontal;
  private BitmapDrawable ship_submarine_vertical;
  private BitmapDrawable ship_submarine_horizontal;
  private BitmapDrawable ship_pt_boat_vertical;
  private BitmapDrawable ship_pt_boat_horizontal;

  private BitmapDrawable grid_green_d;
  private BitmapDrawable grid_blue_d;
  private BitmapDrawable grid_red_d;

  private BitmapDrawable water_d;

  private BitmapDrawable last_orange_d;
  private BitmapDrawable last_green_d;
  private BitmapDrawable last_blue_d;
  private BitmapDrawable last_red_d;

  private BitmapDrawable rank_e1_d;
  private BitmapDrawable rank_e2_d;
  private BitmapDrawable rank_e3_d;
  private BitmapDrawable rank_e4_d;
  private BitmapDrawable rank_e5_d;
  private BitmapDrawable rank_e6_d;
  private BitmapDrawable rank_e7_d;
  private BitmapDrawable rank_e8_d;
  private BitmapDrawable rank_e9_d;
  private BitmapDrawable rank_o1_d;
  private BitmapDrawable rank_o2_d;
  private BitmapDrawable rank_o3_d;
  private BitmapDrawable rank_o4_d;
  private BitmapDrawable rank_o5_d;
  private BitmapDrawable rank_o6_d;
  private BitmapDrawable rank_o7_d;
  private BitmapDrawable rank_o8_d;
  private BitmapDrawable rank_o9_d;
  private BitmapDrawable rank_o10_d;
  private BitmapDrawable rank_o11_d;

  // private NotificationManager mNotificationManager;
  private static final int NOTIFY_STATUS = 0;

  public final static String[] columns = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"};

  private boolean isStarted;
  private boolean paused;

  private final ServiceConnection mConnection = new ServiceConnection()
  {
    @Override
    public void onServiceConnected(final ComponentName className, final IBinder service)
    {
      ((MyService.LocalBinder) service).getService();
    }

    @Override
    public void onServiceDisconnected(final ComponentName className)
    {
    }
  };

  public String checkMyTurn(final int game_id)
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);

    String url = getBaseURL() + "/api/games/" + game_id + "/my_turn.json";
    String s = http.doGet(url);

    db.saveCookies(cookieStore);

    return s;
  }

  public void doBindService()
  {
    if( !isStarted )
    {
      bindService(new Intent(MyApplication.this, MyService.class), mConnection, Context.BIND_AUTO_CREATE);
      Intent service = new Intent(MyApplication.this, MyService.class);
      startService(service);

      isStarted = true;
    }
  }

  public void doGetActivity()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        String s = getActivity();

        int a;

        try
        {
          a = Integer.valueOf(s);
        }
        catch( Exception e )
        {
          a = 0;
        }

        int as = settings.getInt("activity", 0);

        if( a > 0 && as > 0 && a != as && isPaused() )
        {
          showNotify();
        }

        settings.edit().putInt("activity", a).apply();
      }
    }.start();
  }

  private boolean doSound()
  {
    return settings.getBoolean("doSound", false);
  }

  public void doUnbindService()
  {
    if( isStarted )
    {
      unbindService(mConnection);
      isStarted = false;
    }
  }

  private boolean doVibrate()
  {
    return settings.getBoolean("doVibrate", false);
  }

  public String formatTimeLeft(int seconds)
  {
    String left = "";

    int days = seconds / 86400;

    if( days > 0 )
    {
      left += days + " day" + (days == 1 ? "" : "s") + ", ";
      seconds = seconds - days * 86400;
    }

    int hours = seconds / 3600;

    seconds = seconds - hours * 3600;

    int minutes = seconds / 60;

    if( minutes < 0 )
    {
      minutes = 0;
    }

    String m = String.valueOf(minutes);

    if( m.length() == 1 )
    {
      m = "0" + m;
    }

    if( hours < 0 )
    {
      hours = 0;
    }

    left += hours + ":" + m;

    return left;
  }

  private String getActivity()
  {

    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);

    String url = getBaseURL() + "/api/players/activity.json";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public String getBaseURL()
  {
    return getString(R.string.base_url);
  }

  public float getBasicShipSize()
  {
    return getGridSize() / 10.333333f;
  }

  public int getGridOffset()
  {
    return (int)(getGridSize() * 0.034609067178881f);
  }

  public BitmapDrawable getCrosshairD()
  {
    if( crosshair_d == null )
    {
      Matrix matrix = new Matrix();
      Bitmap crosshair_bm = BitmapFactory.decodeResource(getResources(), R.drawable.crosshair);
      matrix.postScale((float) (int) getBasicShipSize() / crosshair_bm.getWidth(), (float) (int) getBasicShipSize() / crosshair_bm.getHeight());
      crosshair_d = new BitmapDrawable(getResources(), Bitmap.createBitmap(crosshair_bm, 0, 0, crosshair_bm.getWidth(), crosshair_bm.getHeight(), matrix, true));
    }

    return crosshair_d;
  }

  public Database getDB()
  {
    return db;
  }

  public void getFriends()
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);

    String url = getBaseURL() + "/api/friends.json";
    String results;

    try
    {
      results = http.doGet(url).trim();
    }
    catch( Exception e )
    {
      results = null;
    }

    db.saveCookies(cookieStore);

    JSONObject o;
    JSONArray ids;
    int id;

    try
    {
      o = new JSONObject(results);
    }
    catch( JSONException e )
    {
      o = null;
      e.printStackTrace();
    }

    if( o == null )
    {
      return;
    }

    try
    {
      ids = o.getJSONArray("ids");
    }
    catch( JSONException e )
    {
      ids = null;
      e.printStackTrace();
    }

    db.deleteFriends();

    if( ids == null )
    {
      return;
    }

    for( int x = 0; x < ids.length(); x++ )
    {
      try
      {
        id = ids.getInt(x);
      }
      catch( JSONException e )
      {
        id = -1;
        e.printStackTrace();
      }

      if( id > 0 )
      {
        db.addFriend(id);
      }
    }
  }

  public String getGame(final int game_id)
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/games/" + game_id + ".json";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public String getGamesCount()
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/games/count.json";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public String getInvitesCount()
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/invites/count.json";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public BitmapDrawable getGridBD(final int current)
  {
    String gridBG;

    if( current == Game.PLAYER )
    {
      gridBG = settings.getString("playerGrid", "Green");
    }
    else
    {
      gridBG = settings.getString("opponentGrid", "Green");
    }

    if( gridBG.contains("Green") )
    {
      return getGridGreenBD();
    }
    else if( gridBG.contains("Red") )
    {
      return getGridRedBD();
    }
    else if( gridBG.contains("Blue") )
    {
      return getGridBlueBD();
    }

    return null;
  }

  private BitmapDrawable getGridBlueBD()
  {
    if( grid_blue_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.grid_blue);
      Matrix matrix = new Matrix();
      matrix.postScale((float) getGridSize() / bm.getWidth(), (float) getGridSize() / bm.getHeight());

      Bitmap b;

      try
      {
        b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), matrix, true);
      }
      catch( Exception e )
      {
        b = null;
      }

      if( b == null )
      {
        return getGridBlueBD();
      }

      grid_blue_d = new BitmapDrawable(getResources(), b);
    }

    return grid_blue_d;
  }

  private BitmapDrawable getGridGreenBD()
  {
    if( grid_green_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.grid_green);
      Matrix matrix = new Matrix();
      matrix.postScale((float) getGridSize() / bm.getWidth(), (float) getGridSize() / bm.getHeight());

      Bitmap b;

      try
      {
        b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), matrix, true);
      }
      catch( Exception e )
      {
        b = null;
      }

      if( b == null )
      {
        return getGridGreenBD();
      }

      grid_green_d = new BitmapDrawable(getResources(), b);
    }

    return grid_green_d;
  }

  private BitmapDrawable getGridRedBD()
  {
    if( grid_red_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.grid_red);
      Matrix matrix = new Matrix();
      matrix.postScale((float) getGridSize() / bm.getWidth(), (float) getGridSize() / bm.getHeight());

      Bitmap b;

      try
      {
        b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), matrix, true);
      }
      catch( Exception e )
      {
        b = null;
      }

      if( b == null )
      {
        return getGridRedBD();
      }

      grid_red_d = new BitmapDrawable(getResources(), b);
    }

    return grid_red_d;
  }

  public int getGridSize()
  {
    return defaultWidth;
  }

  public BitmapDrawable getLastDotBD(final int last_login)
  {
    switch( last_login )
    {
      case 0:
        return getLastDotGreenBD();

      case 1:
        return getLastDotBlueBD();

      case 2:
        return getLastDotOrangeBD();
    }

    return getLastDotRedBD();
  }

  private BitmapDrawable getLastDotBlueBD()
  {
    if( last_blue_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.dot_blue);
      Bitmap b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight());
      last_blue_d = new BitmapDrawable(getResources(), b);
    }

    return last_blue_d;
  }

  private BitmapDrawable getLastDotGreenBD()
  {
    if( last_green_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.dot_green);
      Bitmap b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight());
      last_green_d = new BitmapDrawable(getResources(), b);
    }

    return last_green_d;
  }

  private BitmapDrawable getLastDotOrangeBD()
  {
    if( last_orange_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.dot_orange);
      Bitmap b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight());
      last_orange_d = new BitmapDrawable(getResources(), b);
    }

    return last_orange_d;
  }

  private BitmapDrawable getLastDotRedBD()
  {
    if( last_red_d == null )
    {
      Bitmap bm = BitmapFactory.decodeResource(getResources(), R.drawable.dot_red);
      Bitmap b = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight());
      last_red_d = new BitmapDrawable(getResources(), b);
    }

    return last_red_d;
  }

  public String getNextGame()
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/games/next";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public String getOpponentGame(final int game_id)
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/games/" + game_id + "/opponent.json";
    String s = http.doGet(url);
    db.saveCookies(cookieStore);
    return s;
  }

  public String getPlayerID()
  {
    return String.valueOf(getSettings().getInt("player_id", 0));
  }

  public BitmapDrawable getRankBD(final int r)
  {
    if( r >= 700 && r < 800 )
    {
      return getRankE2BD();
    }
    else if( r >= 800 && r < 900 )
    {
      return getRankE3BD();
    }
    else if( r >= 900 && r < 1000 )
    {
      return getRankE4BD();
    }
    else if( r >= 1000 && r < 1100 )
    {
      return getRankE5BD();
    }
    else if( r >= 1100 && r < 1200 )
    {
      return getRankE6BD();
    }
    else if( r >= 1200 && r < 1300 )
    {
      return getRankE7BD();
    }
    else if( r >= 1300 && r < 1400 )
    {
      return getRankE8BD();
    }
    else if( r >= 1400 && r < 1500 )
    {
      return getRankE9BD();
    }
    else if( r >= 1500 && r < 1600 )
    {
      return getRankO1BD();
    }
    else if( r >= 1600 && r < 1700 )
    {
      return getRankO2BD();
    }
    else if( r >= 1700 && r < 1800 )
    {
      return getRankO3BD();
    }
    else if( r >= 1800 && r < 1850 )
    {
      return getRankO4BD();
    }
    else if( r >= 1850 && r < 1900 )
    {
      return getRankO5BD();
    }
    else if( r >= 1900 && r < 1950 )
    {
      return getRankO6BD();
    }
    else if( r >= 1950 && r < 2000 )
    {
      return getRankO7BD();
    }
    else if( r >= 2000 && r < 2050 )
    {
      return getRankO8BD();
    }
    else if( r >= 2050 && r < 2100 )
    {
      return getRankO9BD();
    }
    else if( r >= 2100 && r < 2150 )
    {
      return getRankO10BD();
    }
    else if( r >= 2150 )
    {
      return getRankO11BD();
    }

    return getRankE1BD();
  }

  private BitmapDrawable getRankE1BD()
  {
    if( rank_e1_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e1);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e1_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e1_d;
  }

  private BitmapDrawable getRankE2BD()
  {
    if( rank_e2_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e2);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e2_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e2_d;
  }

  private BitmapDrawable getRankE3BD()
  {
    if( rank_e3_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e3);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e3_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e3_d;
  }

  private BitmapDrawable getRankE4BD()
  {
    if( rank_e4_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e4);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e4_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e4_d;
  }

  private BitmapDrawable getRankE5BD()
  {
    if( rank_e5_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e5);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e5_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e5_d;
  }

  private BitmapDrawable getRankE6BD()
  {
    if( rank_e6_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e6);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e6_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e6_d;
  }

  private BitmapDrawable getRankE7BD()
  {
    if( rank_e7_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e7);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e7_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e7_d;
  }

  private BitmapDrawable getRankE8BD()
  {
    if( rank_e8_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e8);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e8_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e8_d;
  }

  private BitmapDrawable getRankE9BD()
  {
    if( rank_e9_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.e9);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_e9_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_e9_d;
  }

  private BitmapDrawable getRankO10BD()
  {
    if( rank_o10_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o10);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o10_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o10_d;
  }

  private BitmapDrawable getRankO11BD()
  {
    if( rank_o11_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o11);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o11_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o11_d;
  }

  private BitmapDrawable getRankO1BD()
  {
    if( rank_o1_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o1);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o1_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o1_d;
  }

  private BitmapDrawable getRankO2BD()
  {
    if( rank_o2_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o2);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o2_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o2_d;
  }

  private BitmapDrawable getRankO3BD()
  {
    if( rank_o3_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o3);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o3_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o3_d;
  }

  private BitmapDrawable getRankO4BD()
  {
    if( rank_o4_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o4);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o4_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o4_d;
  }

  private BitmapDrawable getRankO5BD()
  {
    if( rank_o5_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o5);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o5_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o5_d;
  }

  private BitmapDrawable getRankO6BD()
  {
    if( rank_o6_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o6);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o6_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o6_d;
  }

  private BitmapDrawable getRankO7BD()
  {
    if( rank_o7_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o7);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o7_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o7_d;
  }

  private BitmapDrawable getRankO8BD()
  {
    if( rank_o8_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o8);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o8_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o8_d;
  }

  private BitmapDrawable getRankO9BD()
  {
    if( rank_o9_d == null )
    {
      Bitmap b = BitmapFactory.decodeResource(getResources(), R.drawable.o9);
      Bitmap bm = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight());
      rank_o9_d = new BitmapDrawable(getResources(), bm);
    }

    return rank_o9_d;
  }

  public SharedPreferences getSettings()
  {
    return settings;
  }

  public BitmapDrawable getShadowRedBD()
  {
    if( shadow_red_d == null )
    {
      Bitmap shadow_red = BitmapFactory.decodeResource(getResources(), R.drawable.shadow_red);
      Bitmap shadow_red_b = Bitmap.createBitmap(shadow_red, 0, 0, 1, 1);
      shadow_red_d = new BitmapDrawable(getResources(), shadow_red_b);
    }

    return shadow_red_d;
  }

  public BitmapDrawable getShadowWhiteBD()
  {
    if( shadow_white_d == null )
    {
      Bitmap shadow_white = BitmapFactory.decodeResource(getResources(), R.drawable.shadow_white);
      Bitmap shadow_white_b = Bitmap.createBitmap(shadow_white, 0, 0, 1, 1);
      shadow_white_d = new BitmapDrawable(getResources(), shadow_white_b);
    }

    return shadow_white_d;
  }

  public BitmapDrawable getShipBattleshipHorizontalBD(final Ship s)
  {
    if( ship_battleship_horizontal == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.battleship);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_battleship_horizontal = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_battleship_horizontal;
  }

  public BitmapDrawable getShipBattleshipVerticalBD(final Ship s)
  {
    if( ship_battleship_vertical == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.battleship_vertical);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_battleship_vertical = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_battleship_vertical;
  }

  public BitmapDrawable getShipCarrierHorizontalBD(final Ship s)
  {
    if( ship_carrier_horizontal == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.carrier);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_carrier_horizontal = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_carrier_horizontal;
  }

  public BitmapDrawable getShipCarrierVerticalBD(final Ship s)
  {
    if( ship_carrier_vertical == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.carrier_vertical);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_carrier_vertical = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_carrier_vertical;
  }

  public BitmapDrawable getShipDestroyerHorizontalBD(final Ship s)
  {
    if( ship_destroyer_horizontal == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.destroyer);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_destroyer_horizontal = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_destroyer_horizontal;
  }

  public BitmapDrawable getShipDestroyerVerticalBD(final Ship s)
  {
    if( ship_destroyer_vertical == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.destroyer_vertical);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_destroyer_vertical = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_destroyer_vertical;
  }

  public BitmapDrawable getShipPTBoatHorizontalBD(final Ship s)
  {
    if( ship_pt_boat_horizontal == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.pt_boat);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_pt_boat_horizontal = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_pt_boat_horizontal;
  }

  public BitmapDrawable getShipPTBoatVerticalBD(final Ship s)
  {
    if( ship_pt_boat_vertical == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.pt_boat_vertical);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_pt_boat_vertical = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_pt_boat_vertical;
  }

  public BitmapDrawable getShipSubmarineHorizontalBD(final Ship s)
  {
    if( ship_submarine_horizontal == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.submarine);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_submarine_horizontal = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_submarine_horizontal;
  }

  public BitmapDrawable getShipSubmarineVerticalBD(final Ship s)
  {
    if( ship_submarine_vertical == null )
    {
      Bitmap ship_bm = BitmapFactory.decodeResource(getResources(), R.drawable.submarine_vertical);
      Matrix matrix = new Matrix();
      matrix.postScale((float) s.getPixelWidth() / ship_bm.getWidth(), (float) s.getPixelHeight() / ship_bm.getHeight());
      Bitmap ship_b = Bitmap.createBitmap(ship_bm, 0, 0, ship_bm.getWidth(), ship_bm.getHeight(), matrix, true);
      ship_submarine_vertical = new BitmapDrawable(getResources(), ship_b);
    }

    return ship_submarine_vertical;
  }

  public void getPlayers(final int game_id)
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);

    String url;

    if(game_id == 0)
    {
      url = getBaseURL() + "/api/players.json";
    }
    else
    {
      url = getBaseURL() + "/api/players.json?game_id=" + game_id;
    }

    String results;

    try
    {
      results = http.doGet(url).trim();
    }
    catch( Exception e )
    {
      results = null;
    }

    db.saveCookies(cookieStore);
    processNewPlayers(results, game_id == 0);
  }

  public void getPlayersSearch(final String s)
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getBaseURL() + "/api/players.json?s=" + s;
    String results;

    try
    {
      results = http.doGet(url).trim();
    }
    catch( Exception e )
    {
      results = null;
    }

    processNewPlayers(results, false);
  }

  public int getWater()
  {
    int color;

    String waterColor = settings.getString("waterColor", "Blue");

    if( waterColor.contains("Grey") )
    {
      color = R.drawable.water_grey;
    }
    else if( waterColor.contains("Red") )
    {
      color = R.drawable.water_red;
    }
    else if( waterColor.contains("Green") )
    {
      color = R.drawable.water_green;
    }
    else
    {
      color = R.drawable.water_blue;
    }

    return color;
  }

  public Drawable getWaterBD()
  {
    if( water_d == null )
    {
      int color;

      String waterColor = settings.getString("waterColor", "Blue");

      if( waterColor.contains("Grey") )
      {
        color = R.drawable.water_grey;
      }
      else if( waterColor.contains("Red") )
      {
        color = R.drawable.water_red;
      }
      else if( waterColor.contains("Green") )
      {
        color = R.drawable.water_green;
      }
      else
      {
        color = R.drawable.water_blue;
      }

      Bitmap water_bm = BitmapFactory.decodeResource(getResources(), color);
      Bitmap water_b = Bitmap.createBitmap(water_bm, 0, 0, water_bm.getWidth(), water_bm.getHeight());
      water_d = new BitmapDrawable(getResources(), water_b);
    }

    return water_d;
  }

  private boolean isPaused()
  {
    return paused;
  }

  public boolean needToLogin()
  {
    BasicCookieStore cookieStore = db.populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/ping.json";

    String s = http.doGet(url);

    JSONObject o;
    int id = 0;

    try
    {
      o = new JSONObject(s);
    }
    catch( JSONException e )
    {
      o = null;
      e.printStackTrace();
    }

    if( o != null )
    {
      try
      {
        id = o.getInt("id");
      }
      catch( JSONException e )
      {
        e.printStackTrace();
      }
    }

    db.saveCookies(cookieStore);
    return (id == 0);
  }

  @Override
  public void onCreate()
  {
    super.onCreate();

    db = new Database(this);
    db.open();

    settings = PreferenceManager.getDefaultSharedPreferences(this);

    soundManager = new SoundManager();
    soundManager.initSounds(getBaseContext());
    soundManager.addSound(MyApplication.SND_CLICK, R.raw.click);
    soundManager.addSound(MyApplication.SND_EXPLOSION, R.raw.explosion);
    soundManager.addSound(MyApplication.SND_RELOAD, R.raw.reload);
    soundManager.addSound(MyApplication.SND_SPLASH, R.raw.splash);

    vibrator = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);

    isStarted = false;

    if( settings.getBoolean("doNotify", false) )
    {
      doBindService();
    }
  }

  // TODO
//  public void log(final int i)
//  {
//    Log.i("NAUTICAL_WAR", i + "");
//  }
//
//  public void log(final int[] i)
//  {
//    for( int x = 0; x < i.length; x++ )
//    {
//      Log.i("NAUTICAL_WAR", x + " = " + i[x]);
//    }
//  }
//
//  public void log(final String s)
//  {
//    if( s == null )
//    {
//      return;
//    }
//
//    for( String str : s.split("\\n") )
//    {
//      Log.i("NAUTICAL_WAR", str);
//    }
//  }
//
//  public void log(final String[] s)
//  {
//    for( int x = 0; x < s.length; x++ )
//    {
//      Log.i("NAUTICAL_WAR", x + " = " + s[x]);
//    }
//  }

  public int processGame(JSONObject game)
  {
    int id, player1_id, player2_id, turn_id, winner_id, player1_layed_out, player2_layed_out, rated, shots_per_turn, time_limit;
    String updated_at;

    try
    {
      id = game.getInt("id");
    }
    catch( JSONException e )
    {
      id = 0;
      e.printStackTrace();
    }

    try
    {
      updated_at = game.getString("updated_at");
    }
    catch( JSONException e )
    {
      updated_at = "";
      e.printStackTrace();
    }

    try
    {
      player1_id = game.getInt("player1_id");
    }
    catch( JSONException e )
    {
      player1_id = 0;
      e.printStackTrace();
    }

    try
    {
      player2_id = game.getInt("player2_id");
    }
    catch( JSONException e )
    {
      player2_id = 0;
      e.printStackTrace();
    }

    try
    {
      turn_id = game.getInt("turn_id");
    }
    catch( JSONException e )
    {
      turn_id = 0;
      e.printStackTrace();
    }

    try
    {
      winner_id = game.getInt("winner_id");
    }
    catch( JSONException e )
    {
      winner_id = 0;
      e.printStackTrace();
    }

    try
    {
      player1_layed_out = game.getInt("player1_layed_out");
    }
    catch( JSONException e )
    {
      player1_layed_out = 0;
      e.printStackTrace();
    }

    try
    {
      player2_layed_out = game.getInt("player2_layed_out");
    }
    catch( JSONException e )
    {
      player2_layed_out = 0;
      e.printStackTrace();
    }

    try
    {
      rated = game.getInt("rated");
    }
    catch( JSONException e )
    {
      rated = 0;
      e.printStackTrace();
    }

    try
    {
      shots_per_turn = game.getInt("shots_per_turn");
    }
    catch( JSONException e )
    {
      shots_per_turn = 0;
      e.printStackTrace();
    }

    try
    {
      time_limit = game.getInt("t_limit");
    }
    catch( JSONException e )
    {
      time_limit = 0;
      e.printStackTrace();
    }

    if( id > 0 )
    {
      String[] g = db.getGameByID(id);

      if( g == null || g[0].contains("-1") )
      {
        db.addGame(id, player1_id, player2_id, turn_id, winner_id, updated_at, player1_layed_out, player2_layed_out, rated, shots_per_turn, time_limit);
      }
      else
      {
        db.updateGame(id, player1_id, player2_id, turn_id, winner_id, updated_at, player1_layed_out, player2_layed_out, rated, shots_per_turn, time_limit);
      }
    }

    return id;
  }

  public int processPlayer(JSONObject obj)
  {
    String[] player;
    String name;
    int id, wins, losses, rating, last, bot;

    try
    {
      id = obj.getInt("id");
    }
    catch( Exception e )
    {
      id = 0;
    }

    if( id > 0 )
    {
      try
      {
        name = obj.getString("name");
      }
      catch( JSONException e )
      {
        name = null;
        e.printStackTrace();
      }

      try
      {
        wins = obj.getInt("wins");
      }
      catch( JSONException e )
      {
        wins = 0;
        e.printStackTrace();
      }

      try
      {
        losses = obj.getInt("losses");
      }
      catch( JSONException e )
      {
        losses = 0;
        e.printStackTrace();
      }

      try
      {
        rating = obj.getInt("rating");
      }
      catch( JSONException e )
      {
        rating = 0;
        e.printStackTrace();
      }

      try
      {
        last = obj.getInt("last");
      }
      catch( JSONException e )
      {
        last = 0;
        e.printStackTrace();
      }

      try
      {
        bot = obj.getInt("bot");
      }
      catch( JSONException e )
      {
        bot = 0;
        e.printStackTrace();
      }

      player = db.getPlayerByID(id);

      if( player == null || player[0].contains("-1") )
      {
        db.addPlayer(id, name, wins, losses, rating, last, bot);
      }
      else
      {
        db.updatePlayer(id, name, wins, losses, rating, last, bot);
      }
    }

    return id;
  }

  private void processNewPlayers(final String results, final boolean deleteMissing)
  {
    if( results == null )
    {
      return;
    }

    JSONArray players;

    try
    {
      players = new JSONArray(results);
    }
    catch( JSONException e )
    {
      players = null;
      e.printStackTrace();
    }

    if( players == null )
    {
      return;
    }

    ArrayList< Integer > ids = new ArrayList<>(0);
    JSONObject player;

    for( int x = 0; x < players.length(); x++ )
    {
      try
      {
        player = players.getJSONObject(x);
      }
      catch( JSONException e )
      {
        player = null;
        e.printStackTrace();
      }

      if( player != null )
      {
        ids.add(processPlayer(player));
      }
    }

    if( deleteMissing )
    {
      Cursor c = db.getPlayers();
      int id;

      if( c != null && c.moveToFirst() )
      {
        do
        {
          id = c.getInt(c.getColumnIndex(Database.KEY_MASTER_ID));

          if( !ids.contains(id) )
          {
            db.deletePlayer(id);
          }

        } while( c.moveToNext() );

        c.close();
      }
    }
  }

  public void saveLoginCookie(final BasicCookieStore bcs)
  {
    List< Cookie > cookies = bcs.getCookies();
    String name;
    Cookie c;
    Cookie sc = null;

    for( int x = 0; x < cookies.size(); x++ )
    {
      c = cookies.get(x);

      try
      {
        name = c.getName();
      }
      catch( Exception e )
      {
        name = null;
      }

      if( name != null && name.contains("_nauticalwar_session") )
      {
        sc = c;
        break;
      }
    }

    if( sc != null )
    {
      String expires;

      try
      {
        expires = sc.getExpiryDate().toString();
      }
      catch( Exception e )
      {
        expires = "";
      }

      String cookie = sc.getName() + "=" + sc.getValue() + "; domain=" + sc.getDomain() + "; path=" + sc.getPath() + "; expires=" + expires;

      settings.edit().putString("sessionCookie", cookie).apply();
      settings.edit().putString("sessionCookieName", sc.getName()).apply();
      settings.edit().putString("sessionCookieValue", sc.getValue()).apply();
      settings.edit().putString("sessionCookieDomain", sc.getDomain()).apply();
      settings.edit().putString("sessionCookiePath", sc.getPath()).apply();
      settings.edit().putString("sessionCookieExpiry", expires).apply();
      settings.edit().putString("sessionCookieVersion", String.valueOf(sc.getVersion())).apply();
    }
  }

  public void setDefaultWidth(final int w)
  {
    defaultWidth = w;
  }

  public void setPaused(final boolean b)
  {
    paused = b;
  }

  private void showNotify()
  {
    if( !paused )
    {
      return;
    }

    int icon = R.drawable.notification_icon;
    // CharSequence tickerText = "Nautical War  It's your turn!";
    long when = System.currentTimeMillis();
    // Context context = getApplicationContext();
    CharSequence contentTitle = "Nautical War";
    CharSequence contentText = "It's your turn! Click here now!";

    Intent notificationIntent = new Intent(this, Games.class);
    PendingIntent contentIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);

    NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
    Notification.Builder notificationBuilder = new Notification.Builder(this);

    Notification notification = notificationBuilder.setContentIntent(contentIntent).setSmallIcon(icon).setWhen(when).setContentTitle(contentTitle).setContentText(contentText).build();
    // new Notification(icon, tickerText, when);
    // notification.setLatestEventInfo(context, contentTitle, contentText, contentIntent);
    notification.flags |= Notification.FLAG_AUTO_CANCEL;

    if( settings.getBoolean("doNotifySound", false) )
    {
      notification.defaults |= Notification.DEFAULT_SOUND;
    }

    if( settings.getBoolean("doNotifyVibrate", false) )
    {
      notification.vibrate = new long[]{0, 100, 200, 100};
    }

    if( settings.getBoolean("doNotifyBlink", false) )
    {
      notification.ledARGB = 0xff00ff00;
      notification.ledOnMS = 300;
      notification.ledOffMS = 1000;
      notification.flags |= Notification.FLAG_SHOW_LIGHTS;
    }

    if( notificationManager != null )
    {
      notificationManager.notify(MyApplication.NOTIFY_STATUS, notification);
    }
  }

  public void smallScreenHeaderFix(Activity activity)
  {
    if( smallScreen() )
    {
      LinearLayout activity_wrapper = activity.findViewById(R.id.activity_wrapper);
      ((ViewManager) activity_wrapper.getParent()).removeView(activity_wrapper);
    }
  }

  private boolean smallScreen()
  {
    return getGridSize() <= 480;
  }

  public boolean tinyScreen()
  {
    return getGridSize() <= 240;
  }

  public void sndClick()
  {
    if( doSound() )
    {
      soundManager.playSound(MyApplication.SND_CLICK);
    }
  }

  public void sndExplosion()
  {
    if( doSound() )
    {
      soundManager.playSound(MyApplication.SND_EXPLOSION);
    }
  }

  public void sndReload()
  {
    if( doSound() )
    {
      soundManager.playSound(MyApplication.SND_RELOAD);
    }
  }

  public void sndSplash()
  {
    if( doSound() )
    {
      soundManager.playSound(MyApplication.SND_SPLASH);
    }
  }

  public void muteSystemSound()
  {
    if( !doSound() )
    {
      AudioManager mgr = (AudioManager) getSystemService(Context.AUDIO_SERVICE);

      try
      {
        mgr.setStreamMute(AudioManager.STREAM_SYSTEM, true);
      }
      catch( NullPointerException e )
      {
        e.printStackTrace();
      }
    }
  }

  public void unMuteSystemSound()
  {
    AudioManager mgr = (AudioManager) getSystemService(Context.AUDIO_SERVICE);

    try
    {
      mgr.setStreamMute(AudioManager.STREAM_SYSTEM, false);
    }
    catch( NullPointerException e )
    {
      e.printStackTrace();
    }
  }

  public void toast(final Activity a, final String s)
  {
    a.runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        Toast.makeText(a.getBaseContext(), s, Toast.LENGTH_SHORT).show();
      }
    });
  }

  public void toastLong(final Activity a, final String s)
  {
    a.runOnUiThread(new Runnable()
    {
      @Override
      public void run()
      {
        Toast.makeText(a.getBaseContext(), s, Toast.LENGTH_LONG).show();
      }
    });
  }

  public void unbindDrawables(final View v)
  {
    if( v.getBackground() != null )
    {
      v.getBackground().setCallback(null);
    }

    if( v instanceof ViewGroup && !(v instanceof AdapterView) )
    {
      for( int i = 0; i < ((ViewGroup) v).getChildCount(); i++ )
      {
        unbindDrawables(((ViewGroup) v).getChildAt(i));
      }

      ((ViewGroup) v).removeAllViews();
    }
  }

  public void unsetWaterBD()
  {
    water_d = null;
  }

  public void vibrate()
  {
    if( doVibrate() )
    {
      vibrator.vibrate(200);
    }
  }
}
