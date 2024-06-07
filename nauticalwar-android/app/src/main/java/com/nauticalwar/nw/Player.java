package com.nauticalwar.nw;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.text.Html;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;

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

public class Player extends Activity
{
  private final Handler handler = new Handler();
  private MyApplication app;
  private String results;
  private Spinner mode, time;
  private CheckBox rated;
  private String[] player;
  private int player_id;

  private WaitDialog waitDialogAddingInvite;
  private WaitDialog waitDialogAddingFriend;
  private WaitDialog waitDialogAddingEnemy;
  private WaitDialog waitDialogDeletingFriend;

  private final OnClickListener submitClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      int games_count = app.getDB().getGamesCount();

      if( games_count >= 50 )
      {
        app.toast(Player.this, "Maximum of 50 games.\nFinish your other games first.");
      }
      else
      {
        new AlertDialog.Builder(Player.this).setMessage("Are you sure you want to challenge " + player[1] + " to a game?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
        {
          @Override
          public void onClick(final DialogInterface dialog, final int id)
          {
            dialog.cancel();
          }
        }).setPositiveButton("Yes", new DialogInterface.OnClickListener()
        {
          @Override
          public void onClick(final DialogInterface dialog, final int id)
          {
            dialog.cancel();
            submitInviteBegin();
          }
        }).show();
      }
    }
  };

  private final OnClickListener delFriendClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      new AlertDialog.Builder(Player.this).setMessage("Are you sure you want to delete " + player[1] + " from your friends list?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
        }
      }).setPositiveButton("Yes", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
          submitDelFriendBegin();
        }
      }).show();

    }
  };

  private final OnClickListener addEnemyClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      new AlertDialog.Builder(Player.this).setMessage("Are you sure you want to permanently block " + player[1] + "?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
        }
      }).setPositiveButton("Yes", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
          submitEnemyBegin();
        }
      }).show();
    }
  };

  private final OnClickListener addFriendClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      new AlertDialog.Builder(Player.this).setMessage("Are you sure you want to add " + player[1] + " to your friends list?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
        }
      }).setPositiveButton("Yes", new DialogInterface.OnClickListener()
      {
        @Override
        public void onClick(final DialogInterface dialog, final int id)
        {
          dialog.cancel();
          submitFriendBegin();
        }
      }).show();
    }
  };

  private final Runnable updateDeletingFriendResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogDeletingFriend.dismiss();
      updateDeletingFriendUi();
    }
  };

  private final Runnable updateAddingFriendResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogAddingFriend.dismiss();
      updateAddingFriendUi();
    }
  };

  private final Runnable updateAddingEnemyResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogAddingEnemy.dismiss();
      updateAddingEnemyUi();
    }
  };

  private final Runnable updateAddingInviteResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogAddingInvite.dismiss();
      updateAddingInviteUi();
    }
  };

  private void goFriends()
  {
    Intent i = new Intent(this, Friends.class);
    startActivity(i);
    finish();
  }

  private void goInvites()
  {
    Intent i = new Intent(this, Invites.class);
    startActivity(i);
    finish();
  }

  private void goLayout(final int game_id)
  {
    Intent i = new Intent(this, Layout.class);
    i.putExtra("game_id", game_id);
    startActivity(i);
    finish();
  }

  private void goPlayers()
  {
    Intent i = new Intent(this, Players.class);
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
    setContentView(R.layout.player);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    Bundle extras = getIntent().getExtras();

    player_id = 0;

    if( extras != null )
    {
      try
      {
        player_id = extras.getInt("player_id");
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }
    }

    if( player_id == 0 )
    {
      goPlayers();
    }

    player = app.getDB().getPlayerByID(player_id);

    if( player == null || player[0].contains("-1") )
    {
      goPlayers();
    }

    TextView name = findViewById(R.id.player);
    name.setText(player[1]);

    TextView stats = findViewById(R.id.stats);
    stats.setText(Html.fromHtml("Rating: <font color=#00ffff>" + player[4] + "</font> &nbsp; Wins: <font color=#00ff00>" + player[2] + "</font> &nbsp; Losses: <font color=#ff0000>" + player[3] + "</font>"), TextView.BufferType.SPANNABLE);

    mode = findViewById(R.id.mode);
    ArrayAdapter< CharSequence > mode_adapter = ArrayAdapter.createFromResource(this, R.array.mode_array, R.layout.spinner_item);
    mode_adapter.setDropDownViewResource(R.layout.spinner_dropdown_item);
    mode.setAdapter(mode_adapter);

    time = findViewById(R.id.time);
    ArrayAdapter< CharSequence > time_adapter = ArrayAdapter.createFromResource(this, R.array.time_array, R.layout.spinner_item);
    time_adapter.setDropDownViewResource(R.layout.spinner_dropdown_item);
    time.setAdapter(time_adapter);

    rated = findViewById(R.id.rated);

    Button submit = findViewById(R.id.submit);
    submit.setSoundEffectsEnabled(false);
    submit.setOnClickListener(submitClickListener);

    Button add_friend = findViewById(R.id.add_friend);
    add_friend.setSoundEffectsEnabled(false);
    add_friend.setOnClickListener(addFriendClickListener);

    Button add_enemy = findViewById(R.id.add_enemy);
    add_enemy.setSoundEffectsEnabled(false);
    add_enemy.setOnClickListener(addEnemyClickListener);

    Button del_friend = findViewById(R.id.del_friend);
    del_friend.setSoundEffectsEnabled(false);
    del_friend.setOnClickListener(delFriendClickListener);

    LinearLayout body = findViewById(R.id.body);

    if( Integer.valueOf(app.getPlayerID()) == player_id )
    {
      submit.setVisibility(View.GONE);
      add_friend.setVisibility(View.GONE);
      add_enemy.setVisibility(View.GONE);
      del_friend.setVisibility(View.GONE);
      body.setVisibility(View.GONE);
    }
    else
    {
      String friend[] = app.getDB().getFriend(player_id);

      if( friend == null || friend[0].contains("-1") )
      {
        del_friend.setVisibility(View.GONE);
      }
      else
      {
        add_friend.setVisibility(View.GONE);
        add_enemy.setVisibility(View.GONE);
      }
    }

    if( player == null || player[6].contains("1") )
    {
      add_enemy.setVisibility(View.GONE);
    }

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    ImageView image = findViewById(R.id.image);

    int rank;
    try
    {
      rank = Integer.valueOf(player[4]);
    }
    catch( Exception e )
    {
      rank = 0;
    }

    image.setBackground(app.getRankBD(rank));

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.adding_friend));
    waitDialogAddingFriend = new WaitDialog();
    waitDialogAddingFriend.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.adding_enemy));
    waitDialogAddingEnemy = new WaitDialog();
    waitDialogAddingEnemy.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.deleting_friend));
    waitDialogDeletingFriend = new WaitDialog();
    waitDialogDeletingFriend.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.adding_invite));
    waitDialogAddingInvite = new WaitDialog();
    waitDialogAddingInvite.setArguments(args);
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
      goPlayers();
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

  private String postDelFriend()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/friends/" + player_id + ".json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("_method", "delete"));

    String s = null;

    try
    {
      s = http.doPost(url, params).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postEnemy()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/enemies.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("id", String.valueOf(player_id)));

    String s = null;

    try
    {
      s = http.doPost(url, params).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postFriend()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/friends.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("id", String.valueOf(player_id)));

    String s = null;

    try
    {
      s = http.doPost(url, params).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String getShots() {
    int s = 0;

    switch(mode.getSelectedItemPosition()) {
      case 0:
        s = 5;
        break;
      case 1:
        s = 4;
        break;
      case 2:
        s = 3;
        break;
      case 3:
        s = 2;
        break;
      case 4:
        s = 1;
        break;
    }

    return String.valueOf(s);
  }

  private String getTime() {
    int t = 0;

    switch(time.getSelectedItemPosition()) {
      case 0:
        t = 86_400;
        break;
      case 1:
        t = 28_800;
        break;
      case 2:
        t = 3600;
        break;
      case 3:
        t = 900;
        break;
      case 4:
        t = 300;
        break;
    }

    return String.valueOf(t);
  }

  private String postInvite()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/invites.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("id", String.valueOf(player_id)));
    params.add(new BasicNameValuePair("s", getShots()));
    params.add(new BasicNameValuePair("t", getTime()));
    params.add(new BasicNameValuePair("r", rated.isChecked() ? "1" : "0"));

    String s = null;

    try
    {
      s = http.doPost(url, params).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void submitDelFriendBegin()
  {
    waitDialogDeletingFriend.show(getFragmentManager(), "deleting_friend");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postDelFriend();
        handler.post(updateDeletingFriendResults);
      }
    }.start();
  }

  private void submitEnemyBegin()
  {
    waitDialogAddingEnemy.show(getFragmentManager(), "adding_enemy");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postEnemy();
        handler.post(updateAddingEnemyResults);
      }
    }.start();
  }

  private void submitFriendBegin()
  {
    waitDialogAddingFriend.show(getFragmentManager(), "adding_friend");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postFriend();
        handler.post(updateAddingFriendResults);
      }
    }.start();
  }

  private void submitInviteBegin()
  {
    waitDialogAddingInvite.show(getFragmentManager(), "adding_invite");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postInvite();
        handler.post(updateAddingInviteResults);
      }
    }.start();
  }

  private void updateDeletingFriendUi()
  {
    if( results == null )
    {
      app.toast(Player.this, "Server down");
      return;
    }

    JSONObject o;

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
      app.toast(Player.this, "Failed to parse response");
      return;
    }

    int id;

    try
    {
      id = o.getInt("status");
    }
    catch( JSONException e )
    {
      id = -1;
      e.printStackTrace();
    }

    if( id > 0 )
    {
      app.getDB().delFriend(id);
      goFriends();
    }
    else
    {
      app.toast(Player.this, "Failed to delete friend");
    }
  }

  private void updateAddingFriendUi()
  {
    if( results == null )
    {
      app.toast(Player.this, "Server down");
      return;
    }

    JSONObject o;

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
      app.toast(Player.this, "Failed to parse response");
      return;
    }

    int id;

    try
    {
      id = o.getInt("status");
    }
    catch( JSONException e )
    {
      id = -1;
      e.printStackTrace();
    }

    if( id > 0 )
    {
      String[] friend = app.getDB().getFriend(id);

      if( friend == null || friend[0].contains("-1") )
      {
        app.getDB().addFriend(id);
      }

      app.toast(Player.this, "Friend added");

      goFriends();
      return;
    }

    app.toast(Player.this, "Failed to create friend");
  }

  private void updateAddingEnemyUi()
  {
    if( results == null )
    {
      app.toast(Player.this, "Server down");
      return;
    }

    JSONObject o;

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
      app.toast(Player.this, "Failed to parse response");
      return;
    }

    int id;

    try
    {
      id = o.getInt("status");
    }
    catch( JSONException e )
    {
      id = -1;
      e.printStackTrace();
    }

    if( id > 0 )
    {
      String[] player = app.getDB().getPlayerByID(id);

      if( player != null )
      {
        app.getDB().deletePlayer(id);
      }

      app.toast(Player.this, "Player blocked");

      goPlayers();
      return;
    }

    app.toast(Player.this, "Failed to block player");
  }

  private void updateAddingInviteUi()
  {
    if( results == null )
    {
      app.toast(Player.this, "Server down");
      return;
    }

    JSONObject o;
    JSONObject errors;
    JSONArray player2_errors;
    String player2;
    int winner_id = -1;
    int game_id = 0;

    try
    {
      o = new JSONObject(results);
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
        errors = o.getJSONObject("errors");
      }
      catch( JSONException e )
      {
        errors = null;
        // e.printStackTrace();
      }

      if( errors == null )
      {
        try
        {
          winner_id = o.getInt("winner_id");
        }
        catch( JSONException e )
        {
          e.printStackTrace();
        }

        try
        {
          game_id = o.getInt("id");
        }
        catch( JSONException e )
        {
          e.printStackTrace();
        }
      }
      else
      {
        try
        {
          player2_errors = errors.getJSONArray("player2");
        }
        catch( JSONException e )
        {
          player2_errors = null;
          e.printStackTrace();
        }

        if( player2_errors != null )
        {
          try
          {
            player2 = player2_errors.getString(0);
          }
          catch( JSONException e )
          {
            player2 = null;
            e.printStackTrace();
          }

          if( player2 != null )
          {
            app.toast(Player.this, player2);
            return;
          }
        }
      }
    }

    // Bots auto-accepts invites, winner_id only appears in a game response
    if( winner_id == 0 && game_id > 0 )
    {
      goLayout(game_id);
      return;
    }

    goInvites();
  }
}
