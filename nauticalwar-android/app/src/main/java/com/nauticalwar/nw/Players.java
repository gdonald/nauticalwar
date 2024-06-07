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
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Button;
import android.widget.CursorAdapter;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.nauticalwar.fragments.WaitDialog;
import com.nauticalwar.shared.Database;
import com.nauticalwar.shared.MyApplication;

public class Players extends Activity
{
  private MyApplication app;
  private String currentSearch;
  private ListView list;
  private EditText search;
  private final Handler handler = new Handler();
  private int currentSort;
  private String return_to;

  private final String[] sortOptions = {"Rank/Rating", "Online Status", "Name"};

  private WaitDialog waitDialogGettingPlayers;
  private WaitDialog waitDialogSearchingPlayers;

  private final OnClickListener sortOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      showSortOptions();
    }
  };

  private final OnClickListener goOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();

      currentSearch = search.getText().toString().trim();

      InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
      if( imm != null )
      {
        imm.hideSoftInputFromWindow(search.getWindowToken(), 0);
      }

      search();
    }
  };

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
      getPlayers(true);
    }
  };

  private final OnClickListener friendsOnClickListener = new OnClickListener()
  {
    @Override
    public void onClick(final View v)
    {
      app.sndClick();
      goFriends();
    }
  };

  private final Runnable updateGettingPlayers = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogGettingPlayers.dismiss();
      updateGettingPlayersUi();
    }
  };

  private final Runnable updateSearchingPlayers = new Runnable()
  {
    @Override
    public void run()
    {
      waitDialogSearchingPlayers.dismiss();
      updateSearchingPlayersUi();
    }
  };

  private CursorAdapter getPlayerAdapter()
  {
    Cursor c = app.getDB().searchPlayers(currentSearch, currentSort);

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

  private void getPlayers(final boolean force)
  {
    waitDialogGettingPlayers.show(getFragmentManager(), "getting_players");

    new Thread()
    {
      @Override
      public void run()
      {
        long t = System.currentTimeMillis() / 1000;
        long t2 = app.getSettings().getLong("players_cache_time", 0);

        if( force || t2 == 0 || t > t2 + 900 )
        {
          app.getPlayers(0);
          app.getSettings().edit().putLong("players_cache_time", t).apply();
        }

        handler.post(updateGettingPlayers);
      }
    }.start();
  }

  private void goAddInvite(final int player_id)
  {
    Intent i = new Intent(this, Player.class);
    i.putExtra("player_id", player_id);
    startActivity(i);
    finish();
  }

  private void goGames()
  {
    Intent i = new Intent(this, Games.class);
    startActivity(i);
    finish();
  }

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
    startActivity(i);
    finish();
  }

  private void goInvites()
  {
    Intent i = new Intent(this, Invites.class);
    startActivity(i);
    finish();
  }

  private void goFriends()
  {
    Intent i = new Intent(this, Friends.class);
    i.putExtra("return_to", "players");
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
    setContentView(R.layout.players);
    setVolumeControlStream(AudioManager.STREAM_MUSIC);

    app = (MyApplication) getApplication();
    app.getDB().open();

    app.smallScreenHeaderFix(this);

    currentSort = app.getSettings().getInt("currentSort", 0);

    Button sort = findViewById(R.id.sort);
    sort.setSoundEffectsEnabled(false);
    sort.setOnClickListener(sortOnClickListener);

    Button go = findViewById(R.id.go);
    go.setSoundEffectsEnabled(false);
    go.setOnClickListener(goOnClickListener);

    Button refresh = findViewById(R.id.refresh);
    refresh.setSoundEffectsEnabled(false);
    refresh.setOnClickListener(refreshOnClickListener);

    Button friends = findViewById(R.id.friends);
    friends.setSoundEffectsEnabled(false);
    friends.setOnClickListener(friendsOnClickListener);

    list = findViewById(R.id.contacts_list);
    list.setSoundEffectsEnabled(false);
    list.setOnItemClickListener(listClickListener);

    search = findViewById(R.id.search);

    Bundle args = new Bundle();
    args.putString("message", getString(R.string.getting_players));
    waitDialogGettingPlayers = new WaitDialog();
    waitDialogGettingPlayers.setArguments(args);

    args = new Bundle();
    args.putString("message", getString(R.string.searching_players));
    waitDialogSearchingPlayers = new WaitDialog();
    waitDialogSearchingPlayers.setArguments(args);

    currentSearch = "";

    LinearLayout outer = findViewById(R.id.outer);
    outer.setBackgroundResource(app.getWater());

    Bundle extras = getIntent().getExtras();

    if( extras != null )
    {
      try
      {
        return_to = extras.getString("return_to");
      }
      catch( Exception e )
      {
        return_to = "";
      }
    }

    getPlayers(false);
  }

  @Override
  public boolean onKeyDown(final int keyCode, final KeyEvent event)
  {
    if( keyCode == KeyEvent.KEYCODE_BACK )
    {
      if( return_to != null )
      {
        if( return_to.contains("games") )
        {
          goGames();
          return true;
        }
        else if( return_to.contains("invites") )
        {
          goInvites();
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
    app.unMuteSystemSound();
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    app.setPaused(false);
    app.muteSystemSound();
    search.clearFocus();
  }

  private void search()
  {
    if( currentSearch.length() == 0 )
    {
      updateListAdapter();
      app.toast(Players.this, "Search cleared");
    }
    else
    {
      waitDialogSearchingPlayers.show(getFragmentManager(), "searching_players");

      new Thread()
      {
        @Override
        public void run()
        {
          app.getPlayersSearch(currentSearch);
          handler.post(updateSearchingPlayers);
        }
      }.start();
    }
  }

  private void showSortOptions()
  {
    AlertDialog.Builder builder = new AlertDialog.Builder(this);

    builder.setTitle("Sort Players:");

    builder.setSingleChoiceItems(sortOptions, currentSort, new DialogInterface.OnClickListener()
    {
      @Override
      public void onClick(final DialogInterface dialog, final int item)
      {
        String s = sortOptions[item];
        app.toast(Players.this, "Sorting By " + s);
        currentSort = item;
        app.getSettings().edit().putInt("currentSort", currentSort).apply();
        updateListAdapter();
        dialog.cancel();
      }
    });

    AlertDialog alert = builder.create();
    alert.show();
  }

  private void updateListAdapter()
  {
    CursorAdapter adapter = getPlayerAdapter();
    list.setAdapter(adapter);
  }

  private void updateSearchingPlayersUi()
  {
    updateListAdapter();
    app.toast(Players.this, "Search complete");
  }

  private void updateGettingPlayersUi()
  {
    updateListAdapter();
  }
}
