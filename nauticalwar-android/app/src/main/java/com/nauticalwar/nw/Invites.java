package com.nauticalwar.nw;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.database.Cursor;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.text.Html;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Button;
import android.widget.CursorAdapter;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.ActionItem;
import com.nauticalwar.shared.Database;
import com.nauticalwar.shared.MyApplication;
import com.nauticalwar.shared.MyHTTP;
import com.nauticalwar.shared.QuickAction;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class Invites extends Activity
{
  private MyApplication app;
  private final Handler handler = new Handler();
  private ListView list;
  private TextView msg;
  private String results;

  private WaitDialog waitDialogGettingInvites;
  private WaitDialog waitDialogDecliningInvite;
  private WaitDialog waitDialogCancellingInvite;
  private WaitDialog waitDialogAcceptingInvite;
  private WaitDialog waitDialogGettingPlayers;

  private final OnItemClickListener listClickListener = new OnItemClickListener()
  {
    @Override
    public void onItemClick(final AdapterView< ? > parent, final View view, final int position, final long id)
    {
      app.sndClick();

      String[] invite = app.getDB().getInviteByID(view.getId());

      if( invite == null || invite[0].contains("-1") )
      {
        return;
      }

      int player_id;

      try
      {
        player_id = Integer.valueOf(app.getPlayerID());
      }
      catch( Exception e )
      {
        player_id = 0;
      }

      int player1_id;

      try
      {
        player1_id = Integer.valueOf(invite[1]);
      }
      catch( Exception e )
      {
        player1_id = 0;
      }

      QuickAction quickAction = new QuickAction(Invites.this);

      if( player_id == player1_id )
      {
        ActionItem cancel = new ActionItem();
        cancel.setTitle("Cancel Invite");
        cancel.setIcon(getResources().getDrawable(R.drawable.cancel));

        quickAction.addActionItem(cancel);
      }
      else
      {
        ActionItem accept = new ActionItem();
        accept.setTitle("Accept Invite");
        accept.setIcon(getResources().getDrawable(R.drawable.check));

        ActionItem decline = new ActionItem();
        decline.setTitle("Decline Invite");
        decline.setIcon(getResources().getDrawable(R.drawable.decline));

        quickAction.addActionItem(accept);
        quickAction.addActionItem(decline);
      }

      quickAction.setOnActionItemClickListener(new QuickAction.OnActionItemClickListener()
      {
        @Override
        public void onItemClick(final int id, final String title)
        {
          app.sndClick();

          if( title.contains("Decline Invite") )
          {
            declineBegin(id);
            return;
          }

          if( title.contains("Accept Invite") )
          {
            acceptBegin(id);
            return;
          }

          if( title.contains("Cancel Invite") )
          {
            cancelBegin(id);
          }
        }
      });

      quickAction.show(view);
    }
  };

  private final Runnable closeUpdateAcceptInvite = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogAcceptingInvite.dismiss();
      updateAcceptInviteUi();
    }
  };

  private final Runnable closeUpdateDeclineInvite = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogDecliningInvite.dismiss();
      updateDeclineInviteUi();
    }
  };

  private final Runnable closeUpdateCancelInvite = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogCancellingInvite.dismiss();
      updateCancelInviteUi();
    }
  };

  private final Runnable closeUpdateGettingInvites = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingInvites.dismiss();
      updateGettingInvitesUi();
      checkReloadPlayers();
    }
  };

  private final Runnable closeGettingPlayersDialog = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingPlayers.dismiss();
      updateGettingInvitesUi();
    }
  };

  private final OnClickListener newGameOnclickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goPlayers();
    }
  };

  private final OnClickListener refreshOnclickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      getCurrentInvites();
    }
  };

  private final Runnable getInvites = new Runnable()
  {
    @Override
    public void run()
    {
      getCurrentInvites();
    }
  };

  private void acceptBegin(final int invite_id)
  {
    new AlertDialog.Builder(Invites.this).setMessage("Accept invite?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        acceptInvite(invite_id);
        dialog.cancel();
      }
    }).show();
  }

  private void acceptInvite(final int invite_id)
  {
    waitDialogAcceptingInvite.show(getFragmentManager(), "accepting_invite");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postAcceptInvite(invite_id);
        handler.post(closeUpdateAcceptInvite);
      }
    }.start();
  }

  private void cancelBegin(final int invite_id)
  {
    new AlertDialog.Builder(Invites.this).setMessage("Cancel invite?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        cancelInvite(invite_id);
        dialog.cancel();
      }
    }).show();
  }

  private void cancelInvite(final int invite_id)
  {
    waitDialogCancellingInvite.show(getFragmentManager(), "cancelling_invite");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postCancelInvite(invite_id);
        handler.post(closeUpdateCancelInvite);
      }
    }.start();
  }

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
            handler.post(getInvites);
          }
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  private void checkReloadPlayers()
  {
    Cursor c = app.getDB().getInvites();

    if( c == null || c.getCount() == 0 )
    {
      return;
    }

    if( c.moveToFirst() )
    {
      int player1_id, player2_id;
      String[] player1, player2;

      do
      {
        player1_id = 0;

        try
        {
          player1_id = c.getInt(c.getColumnIndex(Database.KEY_PLAYER1));
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }

        player2_id = 0;

        try
        {
          player2_id = c.getInt(c.getColumnIndex(Database.KEY_PLAYER2));
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }

        player1 = app.getDB().getPlayerByID(player1_id);
        player2 = app.getDB().getPlayerByID(player2_id);

        if( player1 == null || player1[0].contains("-1") || player2 == null || player2[0].contains("-1") || player1[4].length() == 0 || player2[4].length() == 0 )
        {
          waitDialogGettingPlayers.show(getFragmentManager(), "getting_players");

          new Thread()
          {
            @Override
            public void run()
            {
              app.getPlayers(0);
              app.getSettings().edit().putLong("players_cache_time", System.currentTimeMillis() / 1000).apply();

              handler.post(closeGettingPlayersDialog);
            }
          }.start();

          break;
        }
      } while( c.moveToNext() );
    }

    c.close();
  }

  private void currentInvites()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = app.getBaseURL() + "/api/invites.json";
    String results = http.doGet(url);
    app.getDB().saveCookies(cookieStore);

    if( results == null )
    {
      app.toast(Invites.this, getString(R.string.server_down));
      return;
    }

    app.getDB().deleteInvites();

    JSONArray invites;
    JSONObject invite;
    int id, player_id_1, player_id_2, time_limit, rated, shots_per_turn;
    String created_at;

    try
    {
      invites = new JSONArray(results);
    }
    catch( JSONException e )
    {
      invites = null;
      e.printStackTrace();
    }

    if( invites != null )
    {
      for( int x = 0; x < invites.length(); x++ )
      {
        try
        {
          invite = invites.getJSONObject(x);
        }
        catch( JSONException e )
        {
          invite = null;
          e.printStackTrace();
        }

        if( invite != null )
        {
          try
          {
            id = invite.getInt("id");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            id = 0;
          }

          try
          {
            player_id_1 = invite.getInt("player1_id");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            player_id_1 = 0;
          }

          try
          {
            player_id_2 = invite.getInt("player2_id");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            player_id_2 = 0;
          }

          try
          {
            time_limit = invite.getInt("time_limit");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            time_limit = 0;
          }

          try
          {
            created_at = invite.getString("created_at");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            created_at = "";
          }

          try
          {
            rated = invite.getInt("rated");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            rated = 1;
          }

          try
          {
            shots_per_turn = invite.getInt("shots_per_turn");
          }
          catch( JSONException e )
          {
            e.printStackTrace();
            shots_per_turn = 1;
          }

          if( id > 0 )
          {
            app.getDB().addInvite(id, player_id_1, player_id_2, created_at, rated, shots_per_turn, time_limit);
          }
        }
      }
    }
  }

  private void declineBegin(final int invite_id)
  {
    new AlertDialog.Builder(Invites.this).setMessage("Decline invite?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        declineInvite(invite_id);
        dialog.cancel();
      }
    }).show();
  }

  private void declineInvite(final int invite_id)
  {
    waitDialogDecliningInvite.show(getFragmentManager(), "declining_invite");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postDeclineInvite(invite_id);
        handler.post(closeUpdateDeclineInvite);
      }
    }.start();
  }

  private void getCurrentInvites()
  {
    waitDialogGettingInvites.show(getFragmentManager(), "getting_invites");

    new Thread()
    {
      @Override
      public void run()
      {
        currentInvites();
        handler.post(closeUpdateGettingInvites);
      }
    }.start();
  }

  private CursorAdapter getInvitesAdapter()
  {
    Cursor c = app.getDB().getInvites();

    if( c.getCount() > 0 )
    {
      msg.setVisibility(View.GONE);
    }
    else
    {
      msg.setVisibility(View.VISIBLE);
    }

    return new CursorAdapter(this, c, CursorAdapter.FLAG_REGISTER_CONTENT_OBSERVER)
    {
      @Override
      public void bindView(final View view, final Context context, final Cursor cursor)
      {
      }

      private View getMyView(final ViewGroup parent, final int position)
      {
        LayoutInflater i = getLayoutInflater();
        View v = i.inflate(R.layout.invite_view, parent, false);

        getCursor().moveToPosition(position);

        int master_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_MASTER_ID));
        int player1_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_PLAYER1));

        int player2_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_PLAYER2));

        v.setId(master_id);

        String[] player1 = app.getDB().getPlayerByID(player1_id);
        String[] player2 = app.getDB().getPlayerByID(player2_id);

        TextView name = v.findViewById(R.id.name);
        TextView stats = v.findViewById(R.id.stats);
        ImageView rated = v.findViewById(R.id.rated);
        ImageView one = v.findViewById(R.id.one);
        ImageView two = v.findViewById(R.id.two);
        ImageView three = v.findViewById(R.id.three);
        ImageView four = v.findViewById(R.id.four);
        ImageView five = v.findViewById(R.id.five);

        name.setText(getString(R.string.player_vs_player, player1[1], player2[1]));

        stats.setText(Html.fromHtml("<font color=#ffffff><b><i>" + player1[4] + "</i></b></font>" + " &nbsp;versus&nbsp; " + "<font color=#ffffff><b><i>" + player2[4] + "</i></b></font><br />"), TextView.BufferType.SPANNABLE);

        if( getCursor().getString(getCursor().getColumnIndex(Database.KEY_RATED)).contains("0") )
        {
          rated.setVisibility(View.GONE);
        }

        one.setVisibility(View.GONE);
        two.setVisibility(View.GONE);
        three.setVisibility(View.GONE);
        four.setVisibility(View.GONE);
        five.setVisibility(View.GONE);

        String shots_per_turn = getCursor().getString(getCursor().getColumnIndex(Database.KEY_SHOTS_PER_TURN));

        if(shots_per_turn.contains("1"))
        {
          one.setVisibility(View.VISIBLE);
        } else if(shots_per_turn.contains("2"))
        {
          two.setVisibility(View.VISIBLE);
        } else if(shots_per_turn.contains("3"))
        {
          three.setVisibility(View.VISIBLE);
        } else if(shots_per_turn.contains("4"))
        {
          four.setVisibility(View.VISIBLE);
        } else if(shots_per_turn.contains("5"))
        {
          five.setVisibility(View.VISIBLE);
        }

        ImageView iv = v.findViewById(R.id.image);
        ImageView iv2 = v.findViewById(R.id.image2);

        int rating;
        int rating2;

        try
        {
          rating = Integer.valueOf(player1[4]);
        }
        catch( Exception e )
        {
          rating = 0;
        }

        try
        {
          rating2 = Integer.valueOf(player2[4]);
        }
        catch( Exception e )
        {
          rating2 = 0;
        }

        iv.setBackground(app.getRankBD(rating));
        iv2.setBackground(app.getRankBD(rating2));

        return v;
      }

      @Override
      public View getView(final int position, final View convertView, final ViewGroup parent)
      {
        return getMyView(parent, position);
      }

      @Override
      public View newView(final Context context, final Cursor cursor, final ViewGroup parent)
      {
        return getMyView(parent, cursor.getPosition());
      }
    };
  }

  private void getListAdapter()
  {
    CursorAdapter adapter = getInvitesAdapter();
    list.setAdapter(adapter);
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
    startActivity(i);
    finish();
  }

  private void goLogin()
  {
    app.toast(Invites.this, "Your session has expired, please login");

    Intent i = new Intent(this, Login.class);
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
    i.putExtra("return_to", "invites");
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
    setContentView(R.layout.invites);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    msg = findViewById(R.id.msg);
    msg.setVisibility(View.GONE);

    Button new_game = findViewById(R.id.new_game);
    new_game.setOnClickListener(newGameOnclickListener);

    Button refresh = findViewById(R.id.refresh);
    refresh.setOnClickListener(refreshOnclickListener);

    list = findViewById(R.id.invites_list);
    list.setOnItemClickListener(listClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.accepting_invite));
    waitDialogAcceptingInvite = new WaitDialog();
    waitDialogAcceptingInvite.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.cancelling_invite));
    waitDialogCancellingInvite = new WaitDialog();
    waitDialogCancellingInvite.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.declining_invite));
    waitDialogDecliningInvite = new WaitDialog();
    waitDialogDecliningInvite.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.getting_invites));
    waitDialogGettingInvites = new WaitDialog();
    waitDialogGettingInvites.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.getting_players));
    waitDialogGettingPlayers = new WaitDialog();
    waitDialogGettingPlayers.setArguments(args);

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
    if( keyCode == KeyEvent.KEYCODE_BACK )
    {
      goHome();
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

  private String postAcceptInvite(final int invite_id)
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/invites/" + invite_id + "/accept.json";

    List< NameValuePair > params = new ArrayList<>();

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postCancelInvite(final int invite_id)
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/invites/" + invite_id + "/cancel.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("_method", "delete"));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postDeclineInvite(final int invite_id)
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/invites/" + invite_id + "/decline.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("_method", "delete"));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void updateAcceptInviteUi()
  {
    if( results == null )
    {
      app.toast(Invites.this, "Failed to accept invite");
      return;
    }

    JSONObject o, game, player;
    int invite_id, game_id;

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
        invite_id = o.getInt("invite_id");
      }
      catch( JSONException e )
      {
        invite_id = 0;
        e.printStackTrace();
      }

      if( invite_id > 0 )
      {
        app.getDB().deleteInvite(invite_id);
        getListAdapter();
      }

      try
      {
        player = o.getJSONObject("player");
      }
      catch( JSONException e )
      {
        player = null;
        e.printStackTrace();
      }

      if( player != null )
      {
        app.processPlayer(player);
      }

      try
      {
        game = o.getJSONObject("game");
      }
      catch( JSONException e )
      {
        game = null;
        e.printStackTrace();
      }

      if( game != null )
      {
        game_id = app.processGame(game);

        if( game_id > 0 )
        {
          app.toast(Invites.this, "Invite accepted");
          goLayout(game_id);
        }
      }
    }
  }

  private void updateCancelInviteUi()
  {
    if( results == null )
    {
      app.toast(Invites.this, getString(R.string.server_down));
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
      app.toast(Invites.this, "Failed to cancel invite");
      return;
    }

    int id;

    try
    {
      id = o.getInt("id");
    }
    catch( Exception e )
    {
      id = 0;
    }

    if( id > 0 )
    {
      app.getDB().deleteInvite(id);
      getListAdapter();
    }
  }

  private void updateDeclineInviteUi()
  {
    if( results == null )
    {
      app.toast(Invites.this, getString(R.string.server_down));
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
      app.toast(Invites.this, "Failed to decline invite");
      return;
    }

    int id;

    try
    {
      id = o.getInt("id");
    }
    catch( Exception e )
    {
      id = 0;
    }

    if( id > 0 )
    {
      app.getDB().deleteInvite(id);
      getListAdapter();
    }
  }

  private void updateGettingInvitesUi()
  {
    getListAdapter();
  }
}
