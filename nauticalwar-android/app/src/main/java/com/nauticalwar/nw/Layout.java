package com.nauticalwar.nw;

import android.annotation.SuppressLint;
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
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.Fleet;
import com.nauticalwar.shared.MyApplication;
import com.nauticalwar.shared.MyHTTP;
import com.nauticalwar.shared.Ship;

import org.apache.http.NameValuePair;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class Layout extends Activity
{
  private RelativeLayout grid;
  private Context context;
  private Fleet playerFleet;
  private Button accept, rotate;
  private MyApplication app;
  private int game_id;
  private final Handler handler = new Handler();
  private String results;
  private Ship ship;
  private int drag_status;
  private final static int START_DRAGGING = 0;
  private final static int STOP_DRAGGING = 1;
  private RelativeLayout border;
  private ImageView image;
  private String selectedShip;

  private WaitDialog waitDialogSavingLayout;

  private final OnTouchListener shipOnTouchListener = new OnTouchListener()
  {
    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouch(final View v, final MotionEvent event)
    {
      selectedShip = (String) v.getTag();

      switch( event.getAction() )
      {
        case MotionEvent.ACTION_CANCEL:
          showHideButtons();
          return true;

        case MotionEvent.ACTION_UP:

          app.sndSplash();

          drag_status = Layout.STOP_DRAGGING;

          image.setOnTouchListener(shipOnTouchListener);

          int top;
          int left;
          if( ship.isVertical() )
          {
            left = (int) event.getRawX() - ship.getPixelWidth() / 2;
            top = (int) event.getRawY() - ship.getPixelHeight() / 2;
          }
          else
          {
            left = (int) event.getRawX() - ship.getPixelWidth() / 2;
            //top = (int) event.getRawY() - ship.getPixelHeight() * 4 / 3;
            top = (int) event.getRawY() - ship.getPixelHeight();
          }

          int c = (int) ((left - app.getGridOffset() + app.getBasicShipSize() / 2) / app.getBasicShipSize());
          int r = (int) ((top - app.getGridOffset() + app.getBasicShipSize() / 2) / app.getBasicShipSize());

          int current_c = ship.getCol();
          int current_r = ship.getRow();

          ship.setPosition(c, r, ship.isVertical());

          if( playerFleet.hasOverlap() )
          {
            ship.setPosition(current_c, current_r, ship.isVertical());
            app.toast(Layout.this, "Ships cannot overlap");
          }
          else
          {
            border.setTag(c + "," + r);
          }

          selectedShip = ship.getColRow();

          drawGrid();
          showHideButtons();

          return true;

        case MotionEvent.ACTION_DOWN:

          drag_status = Layout.START_DRAGGING;

          border = new RelativeLayout(context);
          border.setTag(v.getTag());

          image = new ImageView(context);

          String[] parts = v.getTag().toString().split(",");
          ship = playerFleet.getShipAtLocation(parts[0], parts[1]);

          image.setBackground(ship.getBD());

          if( ship.isVertical() )
          {
            left = (int) event.getRawX() - ship.getPixelWidth() / 2;
            top = (int) event.getRawY() - ship.getPixelHeight() / 2;
          }
          else
          {
            left = (int) event.getRawX() - ship.getPixelWidth() / 2;
            top = (int) event.getRawY() - ship.getPixelHeight() * 4 / 3;
          }

          MarginLayoutParams margin_layout_params = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());
          margin_layout_params.setMargins(left, top, 0, 0);
          LayoutParams layout_params = new LayoutParams(margin_layout_params);

          int color = Color.argb(80, 255, 255, 255);
          border.setBackgroundColor(color);

          MarginLayoutParams mlp2 = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());
          mlp2.setMargins(0, 0, 0, 0);
          LayoutParams lp2 = new LayoutParams(mlp2);

          border.addView(image, lp2);
          grid.addView(border, layout_params);

          return true;

        case MotionEvent.ACTION_MOVE:

          if( drag_status == Layout.START_DRAGGING )
          {
            parts = border.getTag().toString().split(",");
            ship = playerFleet.getShipAtLocation(parts[0], parts[1]);

            if( ship.isVertical() )
            {
              left = (int) event.getRawX() - ship.getPixelWidth() / 2;
              top = (int) event.getRawY() - ship.getPixelHeight() / 2;
            }
            else
            {
              left = (int) event.getRawX() - ship.getPixelWidth() / 2;
              top = (int) event.getRawY() - ship.getPixelHeight() * 4 / 3;
            }

            if( left < app.getGridOffset() )
            {
              left = app.getGridOffset();
            }

            if( left > app.getGridSize() - ship.getPixelWidth() )
            {
              left = app.getGridSize() - ship.getPixelWidth();
            }

            if( top < app.getGridOffset() )
            {
              top = app.getGridOffset();
            }

            if( top > app.getGridSize() - ship.getPixelHeight() )
            {
              top = app.getGridSize() - ship.getPixelHeight();
            }

            margin_layout_params = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());
            margin_layout_params.setMargins(left, top, 0, 0);
            layout_params = new LayoutParams(margin_layout_params);

            border.setLayoutParams(layout_params);
            border.invalidate();
          }

          return true;

        default:
//          return true;
      }

      return false;
    }
  };

  private final OnClickListener rotateClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndSplash();
      handleRotateClick();
    }
  };

  private final OnClickListener gridClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      handleGridClick();
    }
  };
  private final OnClickListener acceptClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      new AlertDialog.Builder(Layout.this).setMessage("Are you sure you want to accept this layout?").setCancelable(false).setNegativeButton("No", new DialogInterface.OnClickListener()
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
          handleAcceptClick();
        }
      }).show();
    }
  };

  private final Runnable updatePostLayoutResults = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogSavingLayout.dismiss();
      updateCreateLayoutUi();
    }
  };

  private final Runnable exitToLogin = new Runnable()
  {
    @Override
    public void run()
    {
      goLogin();
    }
  };

  private void buildNewGame()
  {
    playerFleet.buildNewFleet();
    accept.setVisibility(View.VISIBLE);
    drawGrid();
    app.toast(Layout.this, "Layout your fleet!");
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
            handler.post(exitToLogin);
          }
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }
      }
    }.start();
  }

  @SuppressLint("ClickableViewAccessibility")
  private void drawGrid()
  {
    grid.removeAllViewsInLayout();

    int row, col;
    Ship ship;
    MarginLayoutParams mlp;
    LayoutParams lp;
    RelativeLayout rl, border;

    for( row = 0; row < 10; row++ )
    {
      for( col = 0; col < 10; col++ )
      {
        ship = playerFleet.getShipAtLocation(col, row);

        if( ship != null )
        {
          rl = new RelativeLayout(context);

          mlp = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());

          int left = (int) (app.getBasicShipSize() * col + app.getGridOffset());
          int top = (int) (app.getBasicShipSize() * row + app.getGridOffset());

          mlp.setMargins(left, top, 0, 0);
          lp = new LayoutParams(mlp);

          rl.setBackground(ship.getBD());

          if( selectedShip != null && selectedShip.contains(ship.getColRow()) )
          {
            border = new RelativeLayout(context);
            int color = Color.argb(80, 255, 255, 255);
            border.setBackgroundColor(color);

            MarginLayoutParams mlp2 = new MarginLayoutParams(ship.getPixelWidth(), ship.getPixelHeight());
            mlp2.setMargins(0, 0, 0, 0);
            LayoutParams lp2 = new LayoutParams(mlp2);

            border.addView(rl, lp2);

            grid.addView(border, lp);
          }
          else
          {
            grid.addView(rl, lp);
          }

          rl.setTag(ship.getColRow());
          rl.setOnTouchListener(shipOnTouchListener);
        }
      }
    }
  }

  private void getCurrentFleet()
  {
    String layout = app.getSettings().getString("layout_" + game_id, "");

    if( layout.length() == 0 )
    {
      playerFleet = new Fleet(app);
      buildNewGame();
    }
  }

  private void goGame(final int game_id)
  {
    Intent i = new Intent(this, Game.class);
    i.putExtra("game_id", game_id);
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
    app.toast(Layout.this, "Your session has expired, please login");

    Intent i = new Intent(this, Login.class);
    startActivity(i);
    finish();
  }

  private void handleAcceptClick()
  {
    waitDialogSavingLayout.show(getFragmentManager(), "saving_layout");

    new Thread()
    {
      @Override
      public void run()
      {
        results = postLayout();
        handler.post(updatePostLayoutResults);
      }
    }.start();
  }

  private void handleGridClick()
  {
    selectedShip = "";
    drawGrid();
    showHideButtons();
  }

  private void handleRotateClick()
  {
    if( selectedShip == null || selectedShip.length() == 0 )
    {
      return;
    }

    Ship s = playerFleet.getShipAtLocation(selectedShip);

    if( s == null )
    {
      return;
    }

    int c = s.getCol();
    int r = s.getRow();
    boolean v = s.isVertical();

    s.setVertical(!v);

    if( playerFleet.hasOverlap() )
    {
      s.setCol(c);
      s.setRow(r);
      s.setVertical(v);

      if( playerFleet.hasOverlap() )
      {
        s.setCol(c);
        s.setRow(r);
      }

      app.toast(Layout.this, "Ships cannot overlap");
    }

    selectedShip = s.getColRow();
    drawGrid();
    showHideButtons();
  }

  @Override
  public void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    setContentView(R.layout.layout);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    context = getBaseContext();
    Bundle extras = getIntent().getExtras();

    app = (MyApplication) getApplication();

    accept = findViewById(R.id.accept);
    accept.setOnClickListener(acceptClickListener);

    rotate = findViewById(R.id.rotate);
    rotate.setOnClickListener(rotateClickListener);

    grid = findViewById(R.id.grid);
    grid.setOnClickListener(gridClickListener);

    game_id = 0;

    if( extras != null )
    {
      try
      {
        game_id = extras.getInt("game_id", 0);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }
    }

    if( game_id == 0 )
    {
      goGames();
    }

    RelativeLayout outer = findViewById(R.id.outer);
    outer.setBackground(app.getWaterBD());

    MarginLayoutParams mlp = new MarginLayoutParams(app.getGridSize(), app.getGridSize());
    LayoutParams lp = new LayoutParams(mlp);
    grid.setLayoutParams(lp);
    grid.setBackground(app.getGridBD(Game.PLAYER));

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.saving_layout));
    waitDialogSavingLayout = new WaitDialog();
    waitDialogSavingLayout.setArguments(args);

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
      goGames();
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
    getCurrentFleet();
    drawGrid();
    showHideButtons();
  }

  private String postLayout()
  {
    BasicCookieStore cookieStore = app.getDB().populateCookies();
    MyHTTP http = new MyHTTP(cookieStore);
    String url = getString(R.string.base_url) + "/api/layouts.json";

    List< NameValuePair > params = new ArrayList<>();
    params.add(new BasicNameValuePair("game_id", String.valueOf(game_id)));
    params.add(new BasicNameValuePair("layout", playerFleet.toJSON().toString()));

    String s = http.doPost(url, params);
    app.getDB().saveCookies(cookieStore);

    return s;
  }

  private void showHideButtons()
  {
    if( selectedShip == null || selectedShip.length() == 0 )
    {
      rotate.setVisibility(View.GONE);
    }
    else
    {
      rotate.setVisibility(View.VISIBLE);
    }
  }

  private void updateCreateLayoutUi()
  {
    if( results == null )
    {
      app.toast(Layout.this, "Server down");
      return;
    }

    JSONObject o;
    String errors = null;
    int id = 0;

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
        errors = o.getString("errors");
      }
      catch( JSONException e )
      {
        e.printStackTrace();
      }

      if( errors == null )
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
    }

    if( id > 0 && id == game_id )
    {
      app.toast(Layout.this, "Fleet saved");
      goGame(game_id);
      return;
    }

    if( errors == null )
    {
      errors = "unknown";
    }

    app.toast(Layout.this, "Failed to save fleet: " + errors);
  }
}
