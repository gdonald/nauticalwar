package com.nauticalwar.nw;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import android.text.Html;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.TextView;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.Fleet;
import com.nauticalwar.shared.MyApplication;
import com.nauticalwar.shared.MyHTTP;
import com.nauticalwar.shared.Ship;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

public class Game extends Activity
{
  class checkMyTurnTask extends TimerTask
  {
    @Override
    public void run()
    {
      if(check_my_turn && turn_id != player_id)
      {
        doCheckMyTurn();
      }
      else
      {
        cancel();
      }
    }
  }

  public static final int PLAYER = 0;
  private static final int OPPONENT = 1;
  private static final int CHECK_TIME = 5000;

  private boolean check_my_turn;
  private boolean rated;
  private int shots_per_turn;

  private int time_limit;
  private Timer timer;
  private RelativeLayout grid;

  private Context context;

  private final String[][] hitsAndMisses = new String[ 10 ][ 10 ];
  private final String[][] shots = new String[ 10 ][ 10 ];
  private String[] last_coord, last_hit_miss;
  private Fleet playerFleet;

  private int game_id, turn, turn_id, winner_id, current, player_id, player1_id;
  private String results, player1, player2;
  private MyApplication app;
  private final Handler handler = new Handler();
  private Button player_view, opponent_view, next, fire, skip;
  private TextView status;

  private ImageView rated_icon, one, two, three, four, five;
  private Boolean attacking;
  private boolean beQuiet;

  private WaitDialog waitDialogSkippingOpponent;
  private WaitDialog waitDialogLaunchingAttack;
  private WaitDialog waitDialogLoadingGame;

  private final Runnable updateNextGame = new Runnable()
  {
    @Override
    public void run()
    {
      updateNextGameUi();
    }
  };

  private final Runnable updateSkipTurn = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogSkippingOpponent.dismiss();
      updateSkipTurnUi();
    }
  };

  private final Runnable updateLaunchingAttack = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogLaunchingAttack.dismiss();
      updateLaunchingAttackUi();
    }
  };

  private final Runnable updateCheckMyTurn = new Runnable()
  {
    @Override
    public void run()
    {
      updateCheckMyTurnUi();
    }
  };

  private final Runnable updateDoFetchGame = new Runnable()
  {
    @Override
    public void run()
    {
      doFetchGame();
    }
  };

  private final Runnable updateOpponentLoadingGame = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogLoadingGame.dismiss();
      updateOpponentFetchGameUi();
    }
  };

  private final OnClickListener gridOnClick = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      if(isGameOver())
      {
        app.toast(Game.this, "Game Over");
        return;
      }

      if(turn == Game.OPPONENT)
      {
        if(time_limit < 0)
        {
          askSkipTurn();
        }
        else
        {
          app.toast(Game.this, "Not your turn");
        }

        return;
      }

      if(current == Game.PLAYER)
      {
        app.toast(Game.this, "Cannot attack own fleet\nClick 'Opponent'");
        return;
      }

      if(attacking)
      {
        return;
      }

      String[] parts = v.getTag().toString().split("_");

      if(parts.length != 2)
      {
        return;
      }

      int c;
      int r;

      try
      {
        c = Integer.valueOf(parts[ 0 ]);
        r = Integer.valueOf(parts[ 1 ]);
      }
      catch(Exception e)
      {
        c = -1;
        r = -1;
      }

      if(c > -1 && r > -1)
      {
        if(isCurrentShot(c, r))
        {
          app.sndReload();
          removeShot(c, r);
          drawGrid();
          showHideButtons();
          return;
        }

        if(isValidShot(c, r))
        {
          if(shots_per_turn == 5)
          {
            if(shotCount() >= 5)
            {
              app.toast(Game.this, "Five shots per turn.. press Fire!");
              return;
            }
          }
          else if(shots_per_turn == 4)
          {
            if(shotCount() >= 4)
            {
              app.toast(Game.this, "Four shots per turn.. press Fire!");
              return;
            }
          }
          else if(shots_per_turn == 3)
          {
            if(shotCount() >= 3)
            {
              app.toast(Game.this, "Three shots per turn.. press Fire!");
              return;
            }
          }
          else if(shots_per_turn == 2)
          {
            if(shotCount() >= 2)
            {
              app.toast(Game.this, "Two shots per turn.. press Fire!");
              return;
            }
          }
          else if(shots_per_turn == 1)
          {
            if(shotCount() >= 1)
            {
              app.toast(Game.this, "One shot per turn.. press Fire!");
              return;
            }
          }

          app.sndReload();
          addShot(c, r);
          drawGrid();
          showHideButtons();
          return;
        }

        app.toast(Game.this, "You already tried " + MyApplication.columns[ c ] + "-" + (r + 1));
      }
    }
  };

  private final OnClickListener playerViewOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      if(attacking)
      {
        return;
      }

      switchView(Game.PLAYER);
      goGame(true);
    }
  };

  private final OnClickListener nextOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      switchView(Game.PLAYER);
      goNextGame();
    }
  };

  private final OnClickListener skipOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      askSkipTurn();
    }
  };

  private final OnClickListener fireOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      int sc = shotCount();

      if(shots_per_turn == 5)
      {
        if(sc < 5)
        {
          String msg = "Select five targets";

          switch(sc)
          {
            case 1:
              msg = "Select four more targets";
              break;

            case 2:
              msg = "Select three more targets";
              break;

            case 3:
              msg = "Select two more targets";
              break;

            case 4:
              msg = "Select one more target";
              break;
          }

          app.toast(Game.this, msg);
          return;
        }
      }
      else if(shots_per_turn == 4)
      {
        if(sc < 4)
        {
          String msg = "Select four targets";

          switch(sc)
          {
            case 1:
              msg = "Select three more targets";
              break;

            case 2:
              msg = "Select two more targets";
              break;

            case 3:
              msg = "Select one more target";
              break;
          }

          app.toast(Game.this, msg);
          return;
        }
      }
      else if(shots_per_turn == 3)
      {
        if(sc < 3)
        {
          String msg = "Select three targets";

          switch(sc)
          {
            case 1:
              msg = "Select two more targets";
              break;

            case 2:
              msg = "Select one more target";
              break;
          }

          app.toast(Game.this, msg);
          return;
        }
      }
      else if(shots_per_turn == 2)
      {
        if(sc < 2)
        {
          String msg = "Select two targets";

          if(sc == 1)
          {
            msg = "Select one more target";
          }

          app.toast(Game.this, msg);
          return;
        }
      }
      else if(shots_per_turn == 1)
      {
        if(sc < 1)
        {
          app.toast(Game.this, "Select a target");
          return;
        }
      }

      fire.setEnabled(false);
      doNewAttack();
    }
  };

  private final OnClickListener opponentViewOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      switchView(Game.OPPONENT);
      goGame(true);
    }
  };

  private void addShot(final int col, final int row)
  {
    shots[ col ][ row ] = "X";
  }

  private void askSkipTurn()
  {
    new AlertDialog.Builder(Game.this).setMessage("Are you sure you want to skip your opponent's turn?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
        skipTurn();
        dialog.cancel();
      }
    }).show();
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
          }
          else
          {
            handler.post(updateDoFetchGame);
          }
        }
        catch(Exception e)
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  private void checkMyTurn()
  {
    if(turn_id != player_id)
    {
      check_my_turn = true;

      if(timer == null)
      {
        timer = new Timer();
        timer.schedule(new checkMyTurnTask(), Game.CHECK_TIME, Game.CHECK_TIME);
      }
    }
  }

  private void doCheckMyTurn()
  {
    new Thread()
    {
      @Override
      public void run()
      {
        results = app.checkMyTurn(game_id);
        handler.post(updateCheckMyTurn);
      }
    }.start();
  }

  private void doFetchGame()
  {
    waitDialogLoadingGame.show(getFragmentManager(), "loading_game");

    new Thread()
    {
      @Override
      public void run()
      {
        results = current == Game.PLAYER ? app.getGame(game_id) : app.getOpponentGame(game_id);
        handler.post(updateOpponentLoadingGame);
      }
    }.start();
  }

  private void doNewAttack()
  {
    attacking = true;
    waitDialogLaunchingAttack.show(getFragmentManager(), "launching_attack");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postNewAttack();
        handler.post(updateLaunchingAttack);
      }
    }.start();
  }

  private void drawGrid()
  {
    grid.removeAllViewsInLayout();
    drawGridHitsMisses();
    drawGridShips();
    drawShots();
  }

  private void drawGridHitsMisses()
  {
    int c, r, col, row;
    MarginLayoutParams mlp;
    LayoutParams lp;
    RelativeLayout rl;
    String status;

    for(col = 0; col < 10; col++)
    {
      c = (int) (app.getBasicShipSize() * col + app.getGridOffset());

      for(row = 0; row < 10; row++)
      {
        r = (int) (app.getBasicShipSize() * row + app.getGridOffset());

        mlp = new MarginLayoutParams((int) app.getBasicShipSize() - 1, (int) app.getBasicShipSize() - 1);
        mlp.setMargins(c, r, 0, 0);
        lp = new LayoutParams(mlp);

        rl = new RelativeLayout(context);
        rl.setTag(col + "_" + row);

        rl.setSoundEffectsEnabled(false);
        rl.setOnClickListener(gridOnClick);

        try
        {
          status = hitsAndMisses[ col ][ row ];
        }
        catch(Exception e)
        {
          status = null;
          e.printStackTrace();
        }

        if(status != null)
        {
          if(status.contains("H"))
          {
            rl.setBackground(app.getShadowRedBD());
          }
          else if(status.contains("M"))
          {
            rl.setBackground(app.getShadowWhiteBD());
          }
        }

        grid.addView(rl, lp);
      }
    }
  }

  private void drawGridShips()
  {
    int row, col;
    Ship ship;
    MarginLayoutParams mlp;
    LayoutParams lp;
    RelativeLayout rl;

    for(row = 0; row < 10; row++)
    {
      for(col = 0; col < 10; col++)
      {
        ship = playerFleet.getShipAtLocation(col, row);

        if(ship != null)
        {
          rl = new RelativeLayout(context);

          mlp = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());

          int left = (int) (app.getBasicShipSize() * col + app.getGridOffset());
          int top = (int) (app.getBasicShipSize() * row + app.getGridOffset());

          mlp.setMargins(left, top, 0, 0);
          lp = new LayoutParams(mlp);

          rl.setSoundEffectsEnabled(false);
          rl.setBackground(ship.getBD());

          grid.addView(rl, lp);
        }
      }
    }
  }

  private void drawShots()
  {
    int c, r, col, row;
    MarginLayoutParams mlp;
    LayoutParams lp;
    RelativeLayout rl;
    String shot;

    for(col = 0; col < 10; col++)
    {
      c = (int) (app.getBasicShipSize() * col + app.getGridOffset());

      for(row = 0; row < 10; row++)
      {
        r = (int) (app.getBasicShipSize() * row + app.getGridOffset());

        mlp = new MarginLayoutParams((int) app.getBasicShipSize() - 1, (int) app.getBasicShipSize() - 1);
        mlp.setMargins(c, r, 0, 0);
        lp = new LayoutParams(mlp);

        rl = new RelativeLayout(context);
        rl.setTag(col + "_" + row);

        rl.setSoundEffectsEnabled(false);
        rl.setOnClickListener(gridOnClick);

        try
        {
          shot = shots[ col ][ row ];
        }
        catch(Exception e)
        {
          shot = null;
          e.printStackTrace();
        }

        if(shot != null)
        {
          if(shot.contains("X"))
          {
            rl.setBackground(app.getCrosshairD());

            grid.addView(rl, lp);
          }
        }
      }
    }
  }

  private String getLastLocation()
  {
    StringBuilder locBuilder = new StringBuilder();
    int c, r;

    for(int x = 0; x < 5; x++)
    {
      c = -1;
      r = -1;

      if(last_coord[ x ] != null && last_coord[ x ].contains("_"))
      {
        String[] parts = last_coord[ x ].split("_");

        if(parts.length == 2)
        {
          try
          {
            c = Integer.valueOf(parts[ 0 ]);
            r = Integer.valueOf(parts[ 1 ]);
          }
          catch(Exception e)
          {
            e.printStackTrace();
          }
        }
      }

      if(c > -1 && r > -1)
      {
        locBuilder.append("<font color=#");

        if(last_hit_miss[ x ].contains("H"))
        {
          locBuilder.append("ff0000");
        }
        else
        {
          locBuilder.append("ffffff");
        }

        String s = ">" + MyApplication.columns[ c ] + "-" + (r + 1) + "</font> ";
        locBuilder.append(s);
      }
    }

    return locBuilder.toString().trim();
  }

  private JSONArray getShots()
  {
    JSONArray shotsArray;
    JSONObject shot;

    shotsArray = new JSONArray();

    for(int r = 0; r < 10; r++)
    {
      for(int c = 0; c < 10; c++)
      {
        if(shots[ c ][ r ].length() == 1)
        {
          shot = new JSONObject();

          try
          {
            shot.put("x", c);
          }
          catch(JSONException e)
          {
            e.printStackTrace();
          }

          try
          {
            shot.put("y", r);
          }
          catch(JSONException e)
          {
            e.printStackTrace();
          }

          shotsArray.put(shot);
        }
      }
    }

    return shotsArray;
  }

  private void goGame(final boolean beQuiet)
  {
    app.getSettings().edit().remove("commit").apply();

    Intent i = new Intent(this, Game.class);
    i.putExtra("game_id", game_id);
    i.putExtra("beQuiet", beQuiet);
    startActivity(i);
    finish();
  }

  private void goGames()
  {
    Intent i = new Intent(this, Games.class);
    i.putExtra("game_id", game_id);
    startActivity(i);
    finish();
  }

  private void goLogin()
  {
    app.toast(Game.this, "Your session has expired, please login");

    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void goNextGame()
  {
    app.toast(Game.this, "Finding next game");

    new Thread()
    {
      @Override
      public void run()
      {
        results = app.getNextGame();
        handler.post(updateNextGame);
      }
    }.start();
  }

  private void initHitsAndMisses()
  {
    for(int r = 0; r < 10; r++)
    {
      for(int c = 0; c < 10; c++)
      {
        hitsAndMisses[ c ][ r ] = "";
      }
    }
  }

  private void initShots()
  {
    for(int r = 0; r < 10; r++)
    {
      for(int c = 0; c < 10; c++)
      {
        shots[ c ][ r ] = "";
      }
    }
  }

  private boolean isCurrentShot(final int c, final int r)
  {
    return shots[ c ][ r ].length() == 1;
  }

  private boolean isGameOver()
  {
    return winner_id > 0;
  }

  private boolean isValidShot(final int c, final int r)
  {
    return hitsAndMisses[ c ][ r ].length() == 0;
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.game);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    context = getBaseContext();
    app = (MyApplication) getApplication();

    try
    {
      player_id = Integer.valueOf(app.getPlayerID());
    }
    catch(Exception e)
    {
      e.printStackTrace();
      player_id = 0;
    }

    Bundle extras = getIntent().getExtras();

    game_id = 0;
    beQuiet = false;

    if(extras != null)
    {
      try
      {
        game_id = extras.getInt("game_id");
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }

      try
      {
        beQuiet = extras.getBoolean("beQuiet");
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }
    }

    if(game_id == 0)
    {
      goGames();
    }

    current = app.getSettings().getInt("current", Game.OPPONENT);

    attacking = current == Game.PLAYER;

    last_coord = new String[] { "", "", "", "", "" };
    last_hit_miss = new String[] { "", "", "", "", "" };

    rated_icon = findViewById(R.id.rated);
    rated_icon.setVisibility(View.GONE);

    one = findViewById(R.id.one);
    one.setVisibility(View.GONE);

    two = findViewById(R.id.two);
    two.setVisibility(View.GONE);

    three = findViewById(R.id.three);
    three.setVisibility(View.GONE);

    four = findViewById(R.id.four);
    four.setVisibility(View.GONE);

    five = findViewById(R.id.five);
    five.setVisibility(View.GONE);

    grid = findViewById(R.id.grid);
    MarginLayoutParams mlp = new MarginLayoutParams(app.getGridSize(), app.getGridSize());
    LayoutParams lp = new LayoutParams(mlp);
    grid.setLayoutParams(lp);
    grid.setBackground(app.getGridBD(current));
    grid.setSoundEffectsEnabled(false);

    status = findViewById(R.id.status);

    fire = findViewById(R.id.fire);
    fire.setOnClickListener(fireOnClickListener);
    fire.setVisibility(View.GONE);

    skip = findViewById(R.id.skip);
    skip.setOnClickListener(skipOnClickListener);
    skip.setVisibility(View.GONE);

    next = findViewById(R.id.next);
    next.setOnClickListener(nextOnClickListener);
    next.setVisibility(View.GONE);

    player_view = findViewById(R.id.player_view);
    player_view.setOnClickListener(playerViewOnClickListener);
    player_view.setVisibility(View.GONE);

    opponent_view = findViewById(R.id.opponent_view);
    opponent_view.setOnClickListener(opponentViewOnClickListener);
    opponent_view.setVisibility(View.GONE);

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.launching_attack));
    waitDialogLaunchingAttack = new WaitDialog();
    waitDialogLaunchingAttack.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.loading_game));
    waitDialogLoadingGame = new WaitDialog();
    waitDialogLoadingGame.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.skipping_opponent));
    waitDialogSkippingOpponent = new WaitDialog();
    waitDialogSkippingOpponent.setArguments(args);

    checkIfLoggedIn();

    RelativeLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());
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
      goGames();
      return true;
    }

    return super.onKeyDown(keyCode, event);
  }

  @Override
  public void onPause()
  {
    super.onPause();
    check_my_turn = false;
    app.setPaused(true);
    app.muteSystemSound();
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    app.setPaused(false);
    app.muteSystemSound();
  }

  private void parseGame()
  {
    initHitsAndMisses();
    initShots();

    int x, y;
    String hit;
    JSONObject o;
    JSONObject game, move;
    JSONArray layouts, moves;

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
      app.toast(Game.this, "Can't parse response");
      return;
    }

    try
    {
      game = o.getJSONObject("game");
    }
    catch(JSONException e)
    {
      game = null;
      e.printStackTrace();
    }

    if(game == null)
    {
      app.toast(Game.this, "Can't parse game");
      return;
    }

    int rated_id;
    int shots_per_turn_id;

    player1 = "";
    player2 = "";
    rated = false;
    shots_per_turn = 0;

    try
    {
      player1_id = game.getInt("player1_id");
    }
    catch(Exception e)
    {
      player1_id = 0;
    }

    try
    {
      rated_id = game.getInt("rated");
    }
    catch(Exception e)
    {
      rated_id = 0;
    }

    if(rated_id == 1)
    {
      rated = true;
    }

    try
    {
      shots_per_turn_id = game.getInt("shots_per_turn");
    }
    catch(Exception e)
    {
      shots_per_turn_id = 0;
    }

    if(shots_per_turn_id > 0 && shots_per_turn_id < 6)
    {
      shots_per_turn = shots_per_turn_id;
    }

    try
    {
      time_limit = game.getInt("t_limit");
    }
    catch(Exception e)
    {
      time_limit = 0;
    }

    try
    {
      turn_id = game.getInt("turn_id");
    }
    catch(Exception e)
    {
      turn_id = 0;
    }

    try
    {
      winner_id = game.getInt("winner_id");
    }
    catch(Exception e)
    {
      winner_id = 0;
    }

    if(turn_id > 0)
    {
      turn = turn_id == player_id ? Game.PLAYER : Game.OPPONENT;
    }

    try
    {
      player1 = game.getString("player1_name");
    }
    catch(JSONException e)
    {
      e.printStackTrace();
    }

    try
    {
      player2 = game.getString("player2_name");
    }
    catch(JSONException e)
    {
      e.printStackTrace();
    }

    try
    {
      layouts = o.getJSONArray("layouts");
    }
    catch(JSONException e)
    {
      layouts = null;
      e.printStackTrace();
    }

    if(layouts == null)
    {
      app.toast(Game.this, "Can't parse layouts");
      return;
    }

    try
    {
      moves = o.getJSONArray("moves");
    }
    catch(JSONException e)
    {
      moves = null;
      e.printStackTrace();
    }

    if(moves == null)
    {
      app.toast(Game.this, "Can't parse moves");
      return;
    }

    int max_last = shots_per_turn;

    for(int m = 0; m < moves.length(); m++)
    {
      try
      {
        move = moves.getJSONObject(m);
      }
      catch(JSONException e)
      {
        move = null;
        e.printStackTrace();
      }

      if(move != null)
      {
        try
        {
          x = move.getInt("x");
        }
        catch(JSONException e)
        {
          x = -1;
          e.printStackTrace();
        }

        try
        {
          y = move.getInt("y");
        }
        catch(JSONException e)
        {
          y = -1;
          e.printStackTrace();
        }

        try
        {
          hit = move.getString("hit");
        }
        catch(JSONException e)
        {
          hit = null;
          e.printStackTrace();
        }

        if(x > -1 && y > -1 && hit != null)
        {
          hitsAndMisses[ x ][ y ] = hit;
        }

        if(m < max_last)
        {
          last_coord[ m ] = x + "_" + y;
          last_hit_miss[ m ] = hit;
        }
      }
    }

    playerFleet = new Fleet(app, layouts);
    drawGrid();
    updateStatus();
    showHideButtons();

    if(!beQuiet)
    {
      toastHitOrMiss();
    }

    beQuiet = false;
  }

  private String postNewAttack()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);

    String url = getString(R.string.base_url) + "/api/games/" + game_id + "/attack.json";

    List<NameValuePair> params = new ArrayList<>();
    params.add(new BasicNameValuePair("s", getShots().toString()));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private String postSkipTurn()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/games/" + game_id + "/skip.json";

    List<NameValuePair> params = new ArrayList<>();

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void removeShot(final int col, final int row)
  {
    shots[ col ][ row ] = "";
  }

  private int shotCount()
  {
    int count = 0;

    for(int r = 0; r < 10; r++)
    {
      for(int c = 0; c < 10; c++)
      {
        if(shots[ c ][ r ].length() == 1)
        {
          count++;
        }
      }
    }

    return count;
  }

  private void showHideButtons()
  {
    if(current == Game.PLAYER)
    {
      fire.setVisibility(View.GONE);
      player_view.setVisibility(View.GONE);
      opponent_view.setVisibility(View.VISIBLE);
    }
    else
    {
      fire.setVisibility(View.VISIBLE);
      player_view.setVisibility(View.VISIBLE);
      opponent_view.setVisibility(View.GONE);
    }

    if(turn == Game.OPPONENT)
    {
      fire.setVisibility(View.GONE);
    }

    if(turn == Game.OPPONENT && !isGameOver())
    {
      next.setVisibility(View.VISIBLE);
    }

    if(rated)
    {
      rated_icon.setVisibility(View.VISIBLE);
    }

    if(shots_per_turn == 5)
    {
      five.setVisibility(View.VISIBLE);
      fire.setTextColor(shotCount() >= 5 ? Color.RED : Color.GRAY);
    }
    else if(shots_per_turn == 4)
    {
      four.setVisibility(View.VISIBLE);
      fire.setTextColor(shotCount() >= 4 ? Color.RED : Color.GRAY);
    }
    else if(shots_per_turn == 3)
    {
      three.setVisibility(View.VISIBLE);
      fire.setTextColor(shotCount() >= 3 ? Color.RED : Color.GRAY);
    }
    else if(shots_per_turn == 2)
    {
      two.setVisibility(View.VISIBLE);
      fire.setTextColor(shotCount() >= 2 ? Color.RED : Color.GRAY);
    }
    else if(shots_per_turn == 1)
    {
      one.setVisibility(View.VISIBLE);
      fire.setTextColor(shotCount() >= 1 ? Color.RED : Color.GRAY);
    }

    if(winner_id > 0)
    {
      fire.setVisibility(View.GONE);
    }

    if(turn == Game.OPPONENT && time_limit <= 0)
    {
      skip.setVisibility(View.VISIBLE);
    }
  }

  private void skipTurn()
  {
    waitDialogSkippingOpponent.show(getFragmentManager(), "skipping_opponent");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postSkipTurn();
        handler.post(updateSkipTurn);
      }
    }.start();
  }

  private void switchView(final int who)
  {
    app.getSettings().edit().putInt("current", who).apply();
  }

  private void toastHitOrMiss()
  {
    if(last_hit_miss[ 0 ] == null || last_hit_miss[ 0 ].length() == 0)
    {
      return;
    }

    boolean hit = false;

    for(int x = 0; x < 5; x++)
    {
      if(last_hit_miss[ x ] != null && last_hit_miss[ x ].length() == 1 && last_hit_miss[ x ].contains("H"))
      {
        hit = true;
        break;
      }
    }

    if(hit)
    {
      app.vibrate();
      app.sndExplosion();
    }
    else
    {
      app.sndSplash();
    }

    app.toast(Game.this, hit ? "Hit!" : "Miss!");
  }

  private void updateCheckMyTurnUi()
  {
    if(results == null)
    {
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
      return;
    }

    int status;

    try
    {
      status = o.getInt("status");
    }
    catch(Exception e)
    {
      status = -1;
    }

    if(status == 1)
    {
      switchView(Game.PLAYER);
      goGame(false);
    }
  }

  private void updateLaunchingAttackUi()
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

    if(o == null)
    {
      app.toast(Game.this, "Attack failed.. please try again");
      attacking = false;
      showHideButtons();
      return;
    }

    int status;

    try
    {
      status = o.getInt("status");
    }
    catch(JSONException e)
    {
      status = -1;
      e.printStackTrace();
    }

    if(status == -1)
    {
      app.toast(Game.this, "Attack failed.. please try again");
      attacking = false;
      showHideButtons();
      return;
    }

    attacking = false;
    doFetchGame();
    checkMyTurn();
    fire.setEnabled(true);
  }

  private void updateNextGameUi()
  {
    if(results == null || !results.matches("[0-9]+"))
    {
      goGames();
    }
    else
    {
      try
      {
        game_id = Integer.valueOf(results);
      }
      catch(Exception e)
      {
        game_id = 0;
      }

      if(game_id > 0)
      {
        app.toast(Game.this, "Loading next game");
        switchView(Game.OPPONENT);
        goGame(false);
      }
      else
      {
        app.toast(Game.this, "Next game not found");
        goGames();
      }
    }
  }

  private void updateOpponentFetchGameUi()
  {
    if(results == null)
    {
      app.toast(Game.this, getString(R.string.server_down));
      return;
    }

    parseGame();
    checkMyTurn();
  }

  private void updateSkipTurnUi()
  {
    if(results == null)
    {
      app.toast(Game.this, "Server down");
      return;
    }

    JSONObject o;
    int status = -1;

    try
    {
      o = new JSONObject(results);
    }
    catch(JSONException e)
    {
      o = null;
      e.printStackTrace();
    }

    if(o != null)
    {
      try
      {
        status = o.getInt("status");
      }
      catch(JSONException e)
      {
        e.printStackTrace();
      }
    }

    if(status == -1)
    {
      app.toast(Game.this, "Failed to skip opponent");
      return;
    }

    app.toast(Game.this, "Opponent skipped");
    switchView(Game.OPPONENT);
    goGame(true);
  }

  private void updateStatus()
  {
    String you, opp;

    if(player_id == player1_id)
    {
      you = "<font color=#00ff00>" + player1 + "</font>";
      opp = "<font color=#ff0000>" + player2 + "</font>";
    }
    else
    {
      opp = "<font color=#ff0000>" + player1 + "</font>";
      you = "<font color=#00ff00>" + player2 + "</font>";
    }

    String s = "Fleet: ";
    s += current == Game.PLAYER ? you : opp;

    String last = getLastLocation();

    if(last.length() > 0 && !app.tinyScreen())
    {
      s += shots_per_turn != 1 ? "<br />" : " &nbsp;";
      s += "Last: " + last;
    }

    if(isGameOver())
    {
      s += "<br />Winner: ";
      s += winner_id == player_id ? you : opp;
    }
    else
    {
      s += "<br />Turn: ";
      s += turn_id == player_id ? you : opp;

      String time_left = app.formatTimeLeft(time_limit);

      if(time_left.contains("0:00"))
      {
        time_left = "<font color=#ff0000>" + time_left + "</font>";
      }

      s += " &nbsp;" + time_left;
    }

    status.setText(Html.fromHtml(s), TextView.BufferType.SPANNABLE);
  }
}
