package com.nauticalwar.nw;

import android.app.Activity;
import android.content.Context;
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
import com.nauticalwar.shared.Database;
import com.nauticalwar.shared.MyApplication;

public class Friends extends Activity
{
  private MyApplication app;
  private ListView list;
  private final Handler handler = new Handler();
  private String return_to;

  private WaitDialog waitDialogGettingFriends;

  private final OnItemClickListener listClickListener = new OnItemClickListener()
  {
    @Override
    public void onItemClick(final AdapterView< ? > parent, final View view, final int position, final long id)
    {
      app.sndClick();
      goAddInvite(view.getId());
    }
  };

  private final OnClickListener refreshOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      getFriends(true);
    }
  };

  private final OnClickListener playersOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goPlayers();
    }
  };

  private final Runnable updateFriends = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingFriends.dismiss();
      updateFriendsUi();
    }
  };

  private void getFriends(final boolean force)
  {
    waitDialogGettingFriends.show(getFragmentManager(), "getting_friends");

    new Thread()
    {
      @Override
      public void run()
      {
        long t = System.currentTimeMillis() / 1000;
        long t2 = app.getSettings().getLong("friends_cache_time", 0);

        if( force || t2 == 0 || t > t2 + 900 )
        {
          app.getFriends();

          app.getSettings().edit().putLong("friends_cache_time", t).apply();
        }

        handler.post(updateFriends);
      }
    }.start();
  }

  private CursorAdapter getFriendsAdapter()
  {
    Cursor c = app.getDB().getFriends();

    return new CursorAdapter(this, c, CursorAdapter.FLAG_REGISTER_CONTENT_OBSERVER)
    {
      @Override
      public void bindView(final View view, final Context context, final Cursor cursor)
      {
      }

      private View getMyView(final ViewGroup parent, final int position)
      {
        LayoutInflater i = getLayoutInflater();
        View v = i.inflate(R.layout.player_view, parent, false);

        getCursor().moveToPosition(position);

        v.setId(getCursor().getInt(1));

        TextView name = v.findViewById(R.id.name);
        TextView stats = v.findViewById(R.id.stats);
        ImageView last = v.findViewById(R.id.last_login);

        last.setBackground(app.getLastDotBD(getCursor().getInt(getCursor().getColumnIndex(Database.KEY_LAST_LOGIN))));

        name.setText(getCursor().getString(2));

        stats.setText(Html.fromHtml("<font color=#ffffff><b>Rating:</b></font> " + getCursor().getInt(5) + " &nbsp;<font color=#ffffff><b>Wins:</b></font> <font color=#00ff00>" + getCursor().getInt(3) + "</font> &nbsp;<font color=#ffffff><b>Losses:</b></font> <font color=#ff0000>" + getCursor().getInt(4) + "</font>"), TextView.BufferType.SPANNABLE);

        ImageView iv = v.findViewById(R.id.image);
        iv.setBackground(app.getRankBD(getCursor().getInt(5)));

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

  private void goAddInvite(final int player_id)
  {
    Intent i = new Intent(this, Player.class);
    i.putExtra("player_id", player_id);
    startActivity(i);
    finish();
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
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
    setContentView(R.layout.friends);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    Button refresh = findViewById(R.id.refresh);
    refresh.setSoundEffectsEnabled(false);
    refresh.setOnClickListener(refreshOnClickListener);

    Button players = findViewById(R.id.players);
    players.setSoundEffectsEnabled(false);
    players.setOnClickListener(playersOnClickListener);

    list = findViewById(R.id.contacts_list);
    list.setOnItemClickListener(listClickListener);

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackgroundResource(app.getWater());

    Bundle extras = getIntent().getExtras();

    return_to = "";

    if( extras != null )
    {
      return_to = extras.getString("return_to");
    }

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.getting_friends));
    waitDialogGettingFriends = new WaitDialog();
    waitDialogGettingFriends.setArguments(args);

    getFriends(false);
  }

  @Override
  public boolean onKeyDown(final int keyCode, final KeyEvent event)
  {
    if( keyCode == KeyEvent.KEYCODE_BACK )
    {
      if( return_to != null )
      {
        if( return_to.contains("players") )
        {
          goPlayers();
          return true;
        }
      }

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
    app.muteSystemSound();
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    app.setPaused(false);
    app.muteSystemSound();
  }

  private void updateFriendsUi()
  {
    updateListAdapter();
  }

  private void updateListAdapter()
  {
    CursorAdapter adapter = getFriendsAdapter();
    list.setAdapter(adapter);
  }
}
