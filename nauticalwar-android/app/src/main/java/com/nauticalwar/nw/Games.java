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

public class Games extends Activity
{
  private MyApplication app;
  private final Handler handler = new Handler();
  private ListView list;
  private TextView msg;
  private String results;

  private WaitDialog waitDialogGettingGames;
  private WaitDialog waitDialogGettingPlayers;

  private final OnItemClickListener listClickListener = new OnItemClickListener()
  {
    @Override
    public void onItemClick(final AdapterView<?> parent, final View view, final int position, final long id)
    {
      app.sndClick();

      String[] game = app.getDB().getGameByID(view.getId());

      if(game == null || game[ 0 ].contains("-1"))
      {
        return;
      }

      int player_id;

      try
      {
        player_id = Integer.valueOf(app.getPlayerID());
      }
      catch(Exception e)
      {
        player_id = 0;
      }

      int player1_id;

      try
      {
        player1_id = Integer.valueOf(game[ 1 ]);
      }
      catch(Exception e)
      {
        player1_id = 0;
      }

      int player2_id;

      try
      {
        player2_id = Integer.valueOf(game[ 2 ]);
      }
      catch(Exception e)
      {
        player2_id = 0;
      }

      int winner_id;

      try
      {
        winner_id = Integer.valueOf(game[ 4 ]);
      }
      catch(Exception e)
      {
        winner_id = 0;
      }

      int player1_layed_out;

      try
      {
        player1_layed_out = Integer.valueOf(game[ 6 ]);
      }
      catch(Exception e)
      {
        player1_layed_out = 0;
      }

      int player2_layed_out;

      try
      {
        player2_layed_out = Integer.valueOf(game[ 7 ]);
      }
      catch(Exception e)
      {
        player2_layed_out = 0;
      }

      int t_limit;

      try
      {
        t_limit = Integer.valueOf(game[ 10 ]);
      }
      catch(Exception e)
      {
        t_limit = 0;
      }

      QuickAction quickAction = null;

      try
      {
        quickAction = new QuickAction(Games.this);
      }
      catch(Exception e)
      {
        e.printStackTrace();

        try
        {
          quickAction = new QuickAction(Games.this);
        }
        catch(Exception e2)
        {
          e2.printStackTrace();
        }
      }

      if(quickAction == null)
      {
        return;
      }

      //if(player1_layed_out == 0 || player2_layed_out == 0)
      //{
        if(player_id == player1_id && player1_layed_out == 0 || player_id == player2_id && player2_layed_out == 0)
        {
          if(winner_id == 0)
          {
            ActionItem layout = new ActionItem();
            layout.setTitle("Layout Fleet");
            layout.setIcon(getResources().getDrawable(R.drawable.layout));

            quickAction.addActionItem(layout);
          }
        }
      //}

      if(player1_layed_out == 1 && player2_layed_out == 1)
      {
        ActionItem play = new ActionItem();
        play.setTitle(winner_id > 0 ? "Review Game" : "Play Game");
        play.setIcon(getResources().getDrawable(R.drawable.play));

        quickAction.addActionItem(play);
      }

      if(winner_id > 0)
      {
        ActionItem delete = new ActionItem();
        delete.setTitle("Delete Game");
        delete.setIcon(getResources().getDrawable(R.drawable.delete));

        quickAction.addActionItem(delete);
      }
      else
      {
        if(t_limit < 0 && player_id == player1_id && player2_layed_out == 0 || player_id == player2_id && player1_layed_out == 0)
        {
          ActionItem cancel = new ActionItem();
          cancel.setTitle("Cancel Game");
          cancel.setIcon(getResources().getDrawable(R.drawable.cancel));

          quickAction.addActionItem(cancel);
        }
      }

      quickAction.setOnActionItemClickListener(new QuickAction.OnActionItemClickListener()
      {
        @Override
        public void onItemClick(final int id, final String title)
        {
          app.sndClick();

          if(title.contains("Play Game") || title.contains("Review Game"))
          {
            goGame(id);
            return;
          }

          if(title.contains("Cancel Game"))
          {
            askCancelGame(id);
            return;
          }

          if(title.contains("Layout Fleet"))
          {
            goLayout(id);
            return;
          }

          if(title.contains("Delete Game"))
          {
            askDeleteGame(id);
          }
        }
      });

      quickAction.show(view);
    }
  };

  private final Runnable getGames = new Runnable()
  {
    @Override
    public void run()
    {
      getCurrentGames();
    }
  };

  private final Runnable updateDeleteGame = new Runnable()
  {
    @Override
    public void run()
    {
      updateDeleteUi();
    }
  };

  private final Runnable updateCancelGame = new Runnable()
  {
    @Override
    public void run()
    {
      updateCancelUi();
    }
  };

  private final Runnable closeGettingGamesDialog = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingGames.dismiss();
      updateGettingGamesUi();
      checkReloadPlayers();
    }
  };

  private final Runnable closeGettingPlayersDialog = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingPlayers.dismiss();
      updateGettingGamesUi();
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
      getCurrentGames();
    }
  };

  private void askCancelGame(final int game_id)
  {
    String[] game = app.getDB().getGameByID(game_id);

    int player_id;

    try
    {
      player_id = Integer.valueOf(app.getPlayerID());
    }
    catch(Exception e)
    {
      player_id = 0;
    }

    int player1_id;

    try
    {
      player1_id = Integer.valueOf(game[ 1 ]);
    }
    catch(Exception e)
    {
      player1_id = 0;
    }

    int player2_id;

    try
    {
      player2_id = Integer.valueOf(game[ 2 ]);
    }
    catch(Exception e)
    {
      player2_id = 0;
    }

    int t_limit;

    try
    {
      t_limit = Integer.valueOf(game[ 10 ]);
    }
    catch(Exception e)
    {
      t_limit = 0;
    }

    int player1_layed_out;

    try
    {
      player1_layed_out = Integer.valueOf(game[ 6 ]);
    }
    catch(Exception e)
    {
      player1_layed_out = 0;
    }

    int player2_layed_out;

    try
    {
      player2_layed_out = Integer.valueOf(game[ 7 ]);
    }
    catch(Exception e)
    {
      player2_layed_out = 0;
    }

    String s;

    if(t_limit < 0 && (player_id == player1_id && player2_layed_out == 0 || player_id == player2_id && player1_layed_out == 0))
    {
      s = "Your opponent appears unresponsive, cancel game?";
    } else
    {
      s = "If you cancel you will automatically lose the game. Forfeit game?";
    }

    new AlertDialog.Builder(Games.this).setMessage(s).setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        cancelGame(game_id);
        dialog.cancel();
      }
    }).show();
  }

  private void askDeleteGame(final int game_id)
  {
    new AlertDialog.Builder(Games.this).setMessage("Delete game?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        deleteGame(game_id);
        dialog.cancel();
      }
    }).show();
  }

  private void cancelGame(final int game_id)
  {
    new Thread()
    {
      @Override
      public void run()
      {
        results = postCancelGame(game_id);
        handler.post(updateCancelGame);
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
          if(app.needToLogin())
          {
            goLogin();
          } else
          {
            handler.post(getGames);
          }
        }
        catch(Exception e)
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  private void checkReloadPlayers()
  {
    Cursor c = app.getDB().getGames();

    if(c == null || c.getCount() == 0)
    {
      return;
    }

    if(c.moveToFirst())
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
        catch(Exception e)
        {
          e.printStackTrace();
        }

        player2_id = 0;

        try
        {
          player2_id = c.getInt(c.getColumnIndex(Database.KEY_PLAYER2));
        }
        catch(Exception e)
        {
          e.printStackTrace();
        }

        player1 = app.getDB().getPlayerByID(player1_id);
        player2 = app.getDB().getPlayerByID(player2_id);

        if(player1 == null || player1[ 0 ].contains("-1") || player2 == null || player2[ 0 ].contains("-1") || player1[ 4 ].length() == 0 || player2[ 4 ].length() == 0)
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
      } while(c.moveToNext());
    }

    c.close();
  }

  private void currentGames()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = app.getBaseURL() + "/api/games.json";
    String results = http.doGet(url);
    app.getDB().saveCookies(cookieStore);

    if(results == null)
    {
      app.toast(Games.this, getString(R.string.server_down));
      return;
    }

    ArrayList<Integer> ids = new ArrayList<>(0);

    JSONArray games;
    JSONObject game;
    int id;

    try
    {
      games = new JSONArray(results);
    }
    catch(JSONException e)
    {
      games = null;
      e.printStackTrace();
    }

    if(games != null)
    {
      for(int x = 0; x < games.length(); x++)
      {
        try
        {
          game = games.getJSONObject(x);
        }
        catch(JSONException e)
        {
          game = null;
          e.printStackTrace();
        }

        if(game != null)
        {
          id = app.processGame(game);
          ids.add(id);
        }
      }
    }

    Cursor c = app.getDB().getGames();

    if(c != null && c.moveToFirst())
    {
      do
      {
        id = c.getInt(c.getColumnIndex(Database.KEY_MASTER_ID));

        if(!ids.contains(id))
        {
          app.getDB().deleteGame(id);
        }
      } while(c.moveToNext());
    }
  }

  private void deleteGame(final int game_id)
  {
    new Thread()
    {
      @Override
      public void run()
      {
        results = postDeleteGame(game_id);
        handler.post(updateDeleteGame);
      }
    }.start();
  }

  private void getCurrentGames()
  {
    waitDialogGettingGames.show(getFragmentManager(), "getting_games");

    new Thread()
    {
      @Override
      public void run()
      {
        currentGames();
        handler.post(closeGettingGamesDialog);
      }
    }.start();
  }

  private CursorAdapter getGamesAdapter()
  {
    Cursor c = app.getDB().getGames();

    if(c.getCount() > 0)
    {
      msg.setVisibility(View.GONE);
    } else
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
        View v = null;

        try
        {
          v = i.inflate(R.layout.invite_view, parent, false);
        }
        catch(Exception e)
        {
          e.printStackTrace();

          try
          {
            v = i.inflate(R.layout.invite_view, parent, false);
          }
          catch(Exception e2)
          {
            e2.printStackTrace();
          }
        }

        getCursor().moveToPosition(position);

        int master_id = getCursor().getInt(1);

        try
        {
          v.setId(master_id);
        }
        catch(NullPointerException e)
        {
          e.printStackTrace();
        }

        int player_id;

        try
        {
          player_id = Integer.valueOf(app.getPlayerID());
        }
        catch(Exception e)
        {
          player_id = 0;
        }

        int player1_id;

        try
        {
          player1_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_PLAYER1));
        }
        catch(Exception e)
        {
          player1_id = 0;
        }

        int player2_id;

        try
        {
          player2_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_PLAYER2));
        }
        catch(Exception e)
        {
          player2_id = 0;
        }

        int winner_id;

        try
        {
          winner_id = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_WINNER));
        }
        catch(Exception e)
        {
          winner_id = 0;
        }

        int player1_layed_out;

        try
        {
          player1_layed_out = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_P1_LAYED_OUT));
        }
        catch(Exception e)
        {
          player1_layed_out = 0;
        }

        int player2_layed_out;

        try
        {
          player2_layed_out = getCursor().getInt(getCursor().getColumnIndex(Database.KEY_P2_LAYED_OUT));
        }
        catch(Exception e)
        {
          player2_layed_out = 0;
        }

        int turn_id;

        try
        {
          turn_id = Integer.valueOf(getCursor().getString(getCursor().getColumnIndex(Database.KEY_TURN)));
        }
        catch(Exception e)
        {
          turn_id = 0;
        }

        String[] player1 = app.getDB().getPlayerByID(player1_id);
        String[] player2 = app.getDB().getPlayerByID(player2_id);
        String[] winner = app.getDB().getPlayerByID(winner_id);

        TextView name = v.findViewById(R.id.name);
        TextView stats = v.findViewById(R.id.stats);
        ImageView rated = v.findViewById(R.id.rated);
        ImageView one = v.findViewById(R.id.one);
        ImageView two = v.findViewById(R.id.two);
        ImageView three = v.findViewById(R.id.three);
        ImageView four = v.findViewById(R.id.four);
        ImageView five = v.findViewById(R.id.five);

        String time_left = app.formatTimeLeft(getCursor().getInt(getCursor().getColumnIndex(Database.KEY_T_LIMIT)));

        name.setText(getString(R.string.player_vs_player, player1[ 1 ], player2[ 1 ]));

        String s = "<font color=#cccccc><b><i>" + player1[ 4 ] + "</i></b></font> &nbsp;versus <font color=#cccccc><b><i>" + player2[ 4 ] + "</i></b></font><br />";

        if(winner != null && !winner[ 0 ].contains("-1"))
        {
          s += "<font color=#ff0000><b>Winner:</b> " + winner[ 1 ] + "</font>";
        } else
        {
          if(player_id == player1_id && player1_layed_out == 0 || player_id == player2_id && player2_layed_out == 0)
          {
            s += "<font color=#ff0000><b>Layout Your Fleet!</b></font>";
          }
          else if(player_id != player1_id && player1_layed_out == 0 || player_id != player2_id && player2_layed_out == 0)
          {
            if(time_left.contains("0:00"))
            {
              s += "<font color=#ff0000>";
            } else
            {
              s += "<font color=#ffff00>";
            }

            s += "<b>Opponent Layout: " + time_left + "</b></font>";
          }
          else
          {
            String turn = "<font color=#ff0000>You</font>";

            if(turn_id != player_id)
            {
              if(player_id == player1_id)
              {
                turn = player2[ 1 ];
              }
              else
              {
                turn = player1[ 1 ];
              }

              turn = "<font color=#eeeeee>" + turn + "</font>";
            }

            s += "<b>Turn:</b> " + turn + "  &nbsp;&nbsp;<b>Time Left:</b> ";

            if(time_left.contains("0:00"))
            {
              time_left = "<font color=#ff0000>" + time_left + "</font>";
            }
            else
            {
              time_left = "<font color=#ffffff>" + time_left + "</font>";
            }

            s += time_left;
          }
        }

        stats.setText(Html.fromHtml(s), TextView.BufferType.SPANNABLE);

        if(getCursor().getString(getCursor().getColumnIndex(Database.KEY_RATED)).contains("0"))
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

        int rank;
        int rank2;

        try
        {
          rank = Integer.valueOf(player1[ 4 ]);
        }
        catch(Exception e)
        {
          rank = 0;
        }

        try
        {
          rank2 = Integer.valueOf(player2[ 4 ]);
        }
        catch(Exception e)
        {
          rank2 = 0;
        }

        iv.setBackground(app.getRankBD(rank));
        iv2.setBackground(app.getRankBD(rank2));

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

  private void goGame(final int game_id)
  {
    Intent i = new Intent(this, Game.class);
    i.putExtra("game_id", game_id);
    startActivity(i);
    finish();
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
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

  private void goLogin()
  {
    app.toast(Games.this, "Your session has expired, please login");

    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goPlayers()
  {
    Intent i = new Intent(this, Players.class);
    i.putExtra("return_to", "games");
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
    setContentView(R.layout.games);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    msg = findViewById(R.id.msg);
    msg.setVisibility(View.GONE);

    Button new_game = findViewById(R.id.new_game);
    new_game.setSoundEffectsEnabled(false);
    new_game.setOnClickListener(newGameOnclickListener);

    Button refresh = findViewById(R.id.refresh);
    refresh.setSoundEffectsEnabled(false);
    refresh.setOnClickListener(refreshOnclickListener);

    list = findViewById(R.id.games_list);
    list.setSoundEffectsEnabled(false);
    list.setOnItemClickListener(listClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.getting_games));
    waitDialogGettingGames = new WaitDialog();
    waitDialogGettingGames.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.getting_players));
    waitDialogGettingPlayers = new WaitDialog();
    waitDialogGettingPlayers.setArguments(args);

    checkIfLoggedIn();
    updatePlayersLastGame();
  }

  private void updateGettingPlayersUi()
  {
    updateGettingGamesUi();
  }

  private final Runnable updateGettingPlayers = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingPlayers.dismiss();
      updateGettingPlayersUi();
    }
  };

  private void getPlayers(final int game_id)
  {
    waitDialogGettingPlayers.show(getFragmentManager(), "getting_players");

    new Thread()
    {
      @Override
      public void run()
      {
        app.getPlayers(game_id);
        handler.post(updateGettingPlayers);
      }
    }.start();
  }

  private void updatePlayersLastGame()
  {
    Bundle extra = getIntent().getExtras();
    int game_id;

    try
    {
      game_id = extra.getInt("game_id");
    }
    catch(Exception e)
    {
      game_id = 0;
    }

    if(game_id > 0)
    {
      getPlayers(game_id);
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
    if(keyCode == KeyEvent.KEYCODE_BACK)
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

  private String postCancelGame(final int game_id)
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/games/" + game_id + "cancel.json";

    List<NameValuePair> params = new ArrayList<>();

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postDeleteGame(final int game_id)
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/games/" + game_id + ".json";

    List<NameValuePair> params = new ArrayList<>();
    params.add(new BasicNameValuePair("_method", "delete"));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void updateCancelUi()
  {
    if(results != null)
    {
      JSONObject o;

      try
      {
        o = new JSONObject(results);
      }
      catch(JSONException e)
      {
        o = null;
        e.printStackTrace();
      }

      app.processGame(o);
      updateGettingGamesUi();
    } else
    {
      app.toast(Games.this, "Failed to cancel game");
    }
  }

  private void updateDeleteUi()
  {
    if(results == null)
    {
      app.toast(Games.this, "Server down");
      return;
    }

    JSONObject o;

    try
    {
      o = new JSONObject(results);
    }
    catch(JSONException e)
    {
      o = null;
      e.printStackTrace();
    }

    if(o == null)
    {
      app.toast(Games.this, "Failed to parse response");
      return;
    }

    int id;

    try
    {
      id = o.getInt("status");
    }
    catch(JSONException e)
    {
      id = -1;
      e.printStackTrace();
    }

    if(id > 0)
    {
      app.getDB().deleteGame(id);
      updateGettingGamesUi();
      return;
    }

    app.toast(Games.this, "Failed to delete game");
  }

  private void updateGettingGamesUi()
  {
    CursorAdapter adapter = getGamesAdapter();
    list.setAdapter(adapter);
  }
}
