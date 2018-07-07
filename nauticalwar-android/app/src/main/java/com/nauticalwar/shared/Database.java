package com.nauticalwar.shared;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.cookie.BasicClientCookie;

import java.util.ArrayList;
import java.util.List;

public class Database
{
  private static class DatabaseHelper extends SQLiteOpenHelper
  {
    DatabaseHelper(final Context context)
    {
      super(context, Database.DB_NAME, null, Database.DATABASE_VERSION);
    }

    @Override
    public void onCreate(final SQLiteDatabase db)
    {
      db.execSQL(Database.DB_CREATE_COOKIES);
      db.execSQL(Database.DB_CREATE_PLAYERS);
      db.execSQL(Database.DB_CREATE_INVITES);
      db.execSQL(Database.DB_CREATE_GAMES);
      db.execSQL(Database.DB_CREATE_LAYOUTS);
      db.execSQL(Database.DB_CREATE_MOVES);
      db.execSQL(Database.DB_CREATE_FRIENDS);
    }

    @Override
    public void onUpgrade(final SQLiteDatabase db, final int oldVersion, final int newVersion)
    {
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_COOKIES);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_PLAYERS);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_INVITES);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_GAMES);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_LAYOUTS);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_MOVES);
      db.execSQL("DROP TABLE IF EXISTS " + Database.TB_FRIENDS);

      onCreate(db);
    }
  }

  private static final int DATABASE_VERSION = 2;

  private static final String DB_NAME = "nauticalwar";

  private static final String KEY_ROWID = "_id";
  private static final String KEY_VALUE = "value";
  private static final String KEY_VERSION = "version";
  private static final String KEY_DOMAIN = "domain";
  private static final String KEY_EXPIRY = "expiry";
  private static final String KEY_NAME = "name";
  private static final String KEY_PATH = "path";
  public static final String KEY_MASTER_ID = "master_id";
  public static final String KEY_PLAYER1 = "player1";
  public static final String KEY_PLAYER2 = "player2";
  private static final String KEY_CREATED = "created";
  private static final String KEY_UPDATED = "updated";
  public static final String KEY_TURN = "turn";
  public static final String KEY_WINNER = "winner";
  private static final String KEY_SHIP = "ship";
  private static final String KEY_X = "x";
  private static final String KEY_Y = "y";
  private static final String KEY_VERTICAL = "vertical";
  private static final String KEY_WINS = "wins";
  private static final String KEY_LOSSES = "losses";
  private static final String KEY_RATING = "rating";
  private static final String KEY_BOT = "bot";
  private static final String KEY_GAME = "game";
  public static final String KEY_P1_LAYED_OUT = "p1_layed_out";
  public static final String KEY_P2_LAYED_OUT = "p2_layed_out";
  public static final String KEY_RATED = "rated";
  public static final String KEY_SHOTS_PER_TURN = "shot_per_turn";
  public static final String KEY_T_LIMIT = "t_limit";
  public static final String KEY_LAST_LOGIN = "last_login";

  private static final String TB_COOKIES = "cookies";
  private static final String TB_PLAYERS = "players";
  private static final String TB_GAMES = "games";
  private static final String TB_INVITES = "invites";
  private static final String TB_LAYOUTS = "layouts";
  private static final String TB_MOVES = "moves";
  private static final String TB_FRIENDS = "friends";

  private static final String DB_CREATE_COOKIES = "CREATE TABLE " + Database.TB_COOKIES + " ( _id integer primary key autoincrement, " + Database.KEY_VERSION + " integer not null, " + Database.KEY_NAME + " text not null, " + Database.KEY_VALUE + " text not null, " + Database.KEY_DOMAIN + " text not null, " + Database.KEY_PATH + " text not null, " + Database.KEY_EXPIRY + " text not null );";

  private static final String DB_CREATE_FRIENDS = "CREATE TABLE " + Database.TB_FRIENDS + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null );";

  private static final String DB_CREATE_PLAYERS = "CREATE TABLE " + Database.TB_PLAYERS + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null, " + Database.KEY_NAME + " text not null, " + Database.KEY_WINS + " integer not null, " + Database.KEY_LOSSES + " integer not null, " + Database.KEY_RATING + " integer not null, " + Database.KEY_BOT + " integer not null, " + Database.KEY_LAST_LOGIN + " integer not null );";

  private static final String DB_CREATE_INVITES = "CREATE TABLE " + Database.TB_INVITES + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null, " + Database.KEY_PLAYER1 + " integer not null, " + Database.KEY_PLAYER2 + " integer not null, " + Database.KEY_CREATED + " text not null, " + Database.KEY_RATED + " integer not null, " + Database.KEY_SHOTS_PER_TURN + " integer not null, " + Database.KEY_T_LIMIT + " integer not null );";

  private static final String DB_CREATE_GAMES = "CREATE TABLE " + Database.TB_GAMES + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null, " + Database.KEY_PLAYER1 + " integer not null, " + Database.KEY_PLAYER2 + " integer not null, " + Database.KEY_TURN + " integer, " + Database.KEY_WINNER + " integer, " + Database.KEY_UPDATED + " text not null, " + Database.KEY_P1_LAYED_OUT + " integer not null, " + Database.KEY_P2_LAYED_OUT + " integer not null, " + Database.KEY_RATED + " integer not null, " + Database.KEY_SHOTS_PER_TURN + " integer not null, " + Database.KEY_T_LIMIT + " integer not null );";

  private static final String DB_CREATE_LAYOUTS = "CREATE TABLE " + Database.TB_LAYOUTS + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null, " + Database.KEY_GAME + " integer not null, " + Database.KEY_SHIP + " integer not null, " + Database.KEY_X + " integer not null, " + Database.KEY_Y + " integer not null, " + Database.KEY_VERTICAL + " integer not null );";

  private static final String DB_CREATE_MOVES = "CREATE TABLE " + Database.TB_MOVES + " ( _id integer primary key autoincrement, " + Database.KEY_MASTER_ID + " integer not null, " + Database.KEY_GAME + " integer not null, " + Database.KEY_X + " integer not null, " + Database.KEY_Y + " integer not null, " + Database.KEY_CREATED + " text not null );";

  //private final Context context;
  private final DatabaseHelper dbHelper;
  private boolean open = false;
  private SQLiteDatabase sqlite;

  Database(final Context c)
  {
    //context = c;
    dbHelper = new DatabaseHelper(c);
  }

  private void addCookie(final int version, final String name, final String value, final String domain, final String path, final String expiry)
  {
    if( open )
    {
      ContentValues initialValues = new ContentValues();
      initialValues.put(Database.KEY_VERSION, version);
      initialValues.put(Database.KEY_NAME, name);
      initialValues.put(Database.KEY_VALUE, value);
      initialValues.put(Database.KEY_DOMAIN, domain);
      initialValues.put(Database.KEY_PATH, path);
      initialValues.put(Database.KEY_EXPIRY, expiry);

      try
      {
        sqlite.insert(Database.TB_COOKIES, null, initialValues);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }
    }
  }

  public void addFriend(final int master_id)
  {
    if( open )
    {
      ContentValues initialValues = new ContentValues();
      initialValues.put(Database.KEY_MASTER_ID, master_id);

      sqlite.insert(Database.TB_FRIENDS, null, initialValues);
    }
  }

  public void addGame(final int master_id, final int player1_id, final int player2_id, final int turn_id, final int winner_id, final String updated, final int p1_layed_out, final int p2_layed_out, final int rated, final int shots_per_turn, final int t_limit)
  {
    if( open )
    {
      ContentValues initialValues = new ContentValues();
      initialValues.put(Database.KEY_MASTER_ID, master_id);
      initialValues.put(Database.KEY_PLAYER1, player1_id);
      initialValues.put(Database.KEY_PLAYER2, player2_id);
      initialValues.put(Database.KEY_TURN, turn_id);
      initialValues.put(Database.KEY_WINNER, winner_id);
      initialValues.put(Database.KEY_UPDATED, updated);
      initialValues.put(Database.KEY_P1_LAYED_OUT, p1_layed_out);
      initialValues.put(Database.KEY_P2_LAYED_OUT, p2_layed_out);
      initialValues.put(Database.KEY_RATED, rated);
      initialValues.put(Database.KEY_SHOTS_PER_TURN, shots_per_turn);
      initialValues.put(Database.KEY_T_LIMIT, t_limit);

      sqlite.insert(Database.TB_GAMES, null, initialValues);
    }
  }

  public void addInvite(final int master_id, final int player1_id, final int player2_id, final String created, final int rated, final int shots_per_turn, final int t_limit)
  {
    if( open )
    {
      ContentValues initialValues = new ContentValues();
      initialValues.put(Database.KEY_MASTER_ID, master_id);
      initialValues.put(Database.KEY_PLAYER1, player1_id);
      initialValues.put(Database.KEY_PLAYER2, player2_id);
      initialValues.put(Database.KEY_CREATED, created);
      initialValues.put(Database.KEY_RATED, rated);
      initialValues.put(Database.KEY_SHOTS_PER_TURN, shots_per_turn);
      initialValues.put(Database.KEY_T_LIMIT, t_limit);

      sqlite.insert(Database.TB_INVITES, null, initialValues);
    }
  }

  public void addPlayer(final int master_id, final String name, final int wins, final int losses, final int rating, final int last_login, final int bot)
  {
    if( open )
    {
      ContentValues initialValues = new ContentValues();
      initialValues.put(Database.KEY_MASTER_ID, master_id);
      initialValues.put(Database.KEY_NAME, name);
      initialValues.put(Database.KEY_WINS, wins);
      initialValues.put(Database.KEY_LOSSES, losses);
      initialValues.put(Database.KEY_RATING, rating);
      initialValues.put(Database.KEY_LAST_LOGIN, last_login);
      initialValues.put(Database.KEY_BOT, bot);

      sqlite.insert(Database.TB_PLAYERS, null, initialValues);
    }
  }

  public void close()
  {
    open = false;
    dbHelper.close();
    sqlite.close();
  }

  public void deleteFriends()
  {
    if( open )
    {
      sqlite.delete(Database.TB_FRIENDS, null, null);
    }
  }

  public void deleteGame(final int master_id)
  {
    if( open )
    {
      sqlite.delete(Database.TB_GAMES, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }

  public void deleteInvite(final int master_id)
  {
    if( open )
    {
      sqlite.delete(Database.TB_INVITES, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }

  public void deleteInvites()
  {
    if( open )
    {
      sqlite.delete(Database.TB_INVITES, null, null);
    }
  }

  public void deletePlayer(final int master_id)
  {
    if( open )
    {
      sqlite.delete(Database.TB_PLAYERS, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }

  public void delFriend(final int master_id)
  {
    if( open )
    {
      sqlite.delete(Database.TB_FRIENDS, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }

  private Cursor getCookies()
  {
    if( open )
    {
      return sqlite.query(Database.TB_COOKIES, new String[]{Database.KEY_ROWID, Database.KEY_VERSION, Database.KEY_NAME, Database.KEY_VALUE, Database.KEY_DOMAIN, Database.KEY_PATH, Database.KEY_EXPIRY}, null, null, null, null, null);
    }

    return null;
  }

  public String[] getFriend(final int master_id)
  {
    String[] friend = {"-1"};

    if( open )
    {
      Cursor c = null;

      try
      {
        c = sqlite.query(Database.TB_FRIENDS, new String[]{Database.KEY_MASTER_ID}, Database.KEY_MASTER_ID + " = " + master_id, null, null, null, null);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }

      if( c != null )
      {
        if( c.moveToFirst() )
        {
          friend[0] = c.getString(0);

          try
          {
            c.close();
          }
          catch( Exception e )
          {
            e.printStackTrace();
          }
        }
      }
    }

    return friend;
  }

  public Cursor getFriends()
  {
    if( open )
    {
      ArrayList< String > ids = new ArrayList<>(0);

      Cursor c = sqlite.query(Database.TB_FRIENDS, new String[]{Database.KEY_MASTER_ID}, null, null, null, null, null);

      if( c.moveToFirst() )
      {
        do
        {
          ids.add(c.getString(c.getColumnIndex(Database.KEY_MASTER_ID)));

        } while( c.moveToNext() );

        c.close();
      }

      String[] strArray = new String[ids.size()];

      return sqlite.query(Database.TB_PLAYERS, new String[]{Database.KEY_ROWID, Database.KEY_MASTER_ID, Database.KEY_NAME, Database.KEY_WINS, Database.KEY_LOSSES, Database.KEY_RATING, Database.KEY_LAST_LOGIN}, Database.KEY_MASTER_ID + " IN (" + join(ids.toArray(strArray)) + ")", null, null, null, null);
    }

    return null;
  }

  public String[] getGameByID(final int master_id)
  {
    String[] game = {"-1", "", "", "", "", "", "", "", "", "", ""};

    if( open )
    {
      Cursor c = null;

      try
      {
        c = sqlite.query(Database.TB_GAMES, new String[]{Database.KEY_MASTER_ID, Database.KEY_PLAYER1, Database.KEY_PLAYER2, Database.KEY_TURN, Database.KEY_WINNER, Database.KEY_UPDATED, Database.KEY_P1_LAYED_OUT, Database.KEY_P2_LAYED_OUT, Database.KEY_RATED, Database.KEY_SHOTS_PER_TURN, Database.KEY_T_LIMIT}, Database.KEY_MASTER_ID + " = " + master_id, null, null, null, null);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }

      if( c != null && c.moveToFirst() )
      {
        game[0] = c.getString(0);
        game[1] = c.getString(1);
        game[2] = c.getString(2);
        game[3] = c.getString(3);
        game[4] = c.getString(4);
        game[5] = c.getString(5);
        game[6] = c.getString(6);
        game[7] = c.getString(7);
        game[8] = c.getString(8);
        game[9] = c.getString(9);
        game[10] = c.getString(10);

        c.close();
      }
    }

    return game;
  }

  public Cursor getGames()
  {
    if( open )
    {
      return sqlite.query(Database.TB_GAMES, new String[]{Database.KEY_ROWID, Database.KEY_MASTER_ID, Database.KEY_PLAYER1, Database.KEY_PLAYER2, Database.KEY_TURN, Database.KEY_WINNER, Database.KEY_UPDATED, Database.KEY_P1_LAYED_OUT, Database.KEY_P2_LAYED_OUT, Database.KEY_RATED, Database.KEY_SHOTS_PER_TURN, Database.KEY_T_LIMIT}, null, null, null, null, Database.KEY_UPDATED + " DESC");
    }

    return null;
  }

  public int getGamesCount()
  {
    if( open )
    {
      return sqlite.query(Database.TB_GAMES, new String[]{Database.KEY_ROWID}, null, null, null, null, null).getCount();
    }

    return 0;
  }

  public String[] getInviteByID(final int invite_id)
  {
    String[] invite = {"-1", "", "", "", "", "", ""};

    if( open )
    {
      Cursor c = sqlite.query(Database.TB_INVITES, new String[]{Database.KEY_MASTER_ID, Database.KEY_PLAYER1, Database.KEY_PLAYER2, Database.KEY_CREATED, Database.KEY_RATED, Database.KEY_SHOTS_PER_TURN, Database.KEY_T_LIMIT}, Database.KEY_MASTER_ID + " = " + invite_id, null, null, null, null);

      if( c.moveToFirst() )
      {
        invite[0] = c.getString(0);
        invite[1] = c.getString(1);
        invite[2] = c.getString(2);
        invite[3] = c.getString(3);
        invite[4] = c.getString(4);
        invite[5] = c.getString(5);
        invite[6] = c.getString(6);

        c.close();
      }
    }

    return invite;
  }

  public Cursor getInvites()
  {
    if( open )
    {
      return sqlite.query(Database.TB_INVITES, new String[]{Database.KEY_ROWID, Database.KEY_MASTER_ID, Database.KEY_PLAYER1, Database.KEY_PLAYER2, Database.KEY_CREATED, Database.KEY_RATED, Database.KEY_SHOTS_PER_TURN, Database.KEY_T_LIMIT}, null, null, null, null, Database.KEY_CREATED);
    }

    return null;
  }

  public String[] getPlayerByID(final int player_id)
  {
    String[] player = {"-1", "", "", "", "", "", ""};

    if( open )
    {
      Cursor c = null;

      try
      {
        c = sqlite.query(Database.TB_PLAYERS, new String[]{Database.KEY_MASTER_ID, Database.KEY_NAME, Database.KEY_WINS, Database.KEY_LOSSES, Database.KEY_RATING, Database.KEY_LAST_LOGIN, Database.KEY_BOT}, Database.KEY_MASTER_ID + " = " + player_id, null, null, null, Database.KEY_RATING + " DESC");
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }

      if( c != null )
      {
        if( c.moveToFirst() )
        {
          player[0] = c.getString(0);
          player[1] = c.getString(1);
          player[2] = c.getString(2);
          player[3] = c.getString(3);
          player[4] = c.getString(4);
          player[5] = c.getString(5);
          player[6] = c.getString(6);

          try
          {
            c.close();
          }
          catch( Exception e )
          {
            e.printStackTrace();
          }
        }
      }
    }

    return player;
  }

  public Cursor getPlayers()
  {
    if( open )
    {
      return sqlite.query(Database.TB_PLAYERS, new String[]{Database.KEY_ROWID, Database.KEY_MASTER_ID, Database.KEY_NAME, Database.KEY_WINS, Database.KEY_LOSSES, Database.KEY_RATING, Database.KEY_LAST_LOGIN}, null, null, null, null, Database.KEY_RATING + " DESC");
    }

    return null;
  }

  private String join(final String[] s)
  {
    int k = s.length;

    if( k == 0 )
    {
      return "";
    }

    StringBuilder out = new StringBuilder();

    out.append(s[0]);

    for( int x = 1; x < k; ++x )
    {
      if( s[x] != null )
      {
        out.append(",").append(s[x]);
      }
    }

    return out.toString();
  }

  public void open() throws SQLException
  {
    if( open )
    {
      return;
    }

    open = true;
    sqlite = dbHelper.getWritableDatabase();
  }

  public BasicCookieStore populateCookies()
  {
    BasicCookieStore cookieStore = new BasicCookieStore();
    Cursor c = getCookies();

    if( c != null )
    {
      if( c.moveToFirst() )
      {
        BasicClientCookie cookie;

        do
        {
          cookie = new BasicClientCookie(c.getString(2), c.getString(3));

          cookie.setVersion(c.getInt(1));
          cookie.setDomain(c.getString(4));
          cookie.setPath(c.getString(5));
          cookieStore.addCookie(cookie);

        } while( c.moveToNext() );
      }

      c.close();
    }

    return cookieStore;
  }

  public void saveCookies(final BasicCookieStore cookieStore)
  {
    if( open )
    {
      try
      {
        sqlite.delete(Database.TB_COOKIES, null, null);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }

      if( cookieStore != null )
      {
        List< Cookie > cookies = null;

        try
        {
          cookies = cookieStore.getCookies();
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }

        if( cookies != null )
        {
          for( int i = 0; i < cookies.size(); i++ )
          {
            if( open )
            {
              addCookie(cookies.get(i).getVersion(), cookies.get(i).getName(), cookies.get(i).getValue(), cookies.get(i).getDomain(), cookies.get(i).getPath(), String.valueOf(cookies.get(i).getExpiryDate()));
            }
          }
        }
      }
    }
  }

  public Cursor searchPlayers(final String s, final int currentSort)
  {
    String where = null;
    String ss = null;
    String sort = Database.KEY_RATING + " DESC";

    switch( currentSort )
    {
      case 1:
        sort = Database.KEY_LAST_LOGIN;
        break;

      case 2:
        sort = Database.KEY_NAME;
        break;
    }

    if( s != null )
    {
      ss = s.trim();
    }

    if( ss != null && ss.length() > 0 )
    {
      where = Database.KEY_NAME + " LIKE '%" + ss + "%'";
    }

    if( open )
    {
      try
      {
        return sqlite.query(Database.TB_PLAYERS, new String[]{Database.KEY_ROWID, Database.KEY_MASTER_ID, Database.KEY_NAME, Database.KEY_WINS, Database.KEY_LOSSES, Database.KEY_RATING, Database.KEY_LAST_LOGIN}, where, null, null, null, sort);
      }
      catch( Exception e )
      {
        e.printStackTrace();
      }
    }

    return null;
  }

  public void updateGame(final int master_id, final int player1_id, final int player2_id, final int turn_id, final int winner_id, final String updated, final int p1_layed_out, final int p2_layed_out, final int rated, final int shots_per_turn, final int t_limit)
  {
    if( open )
    {
      ContentValues nv = new ContentValues();
      nv.put(Database.KEY_MASTER_ID, master_id);
      nv.put(Database.KEY_PLAYER1, player1_id);
      nv.put(Database.KEY_PLAYER2, player2_id);
      nv.put(Database.KEY_TURN, turn_id);
      nv.put(Database.KEY_WINNER, winner_id);
      nv.put(Database.KEY_UPDATED, updated);
      nv.put(Database.KEY_P1_LAYED_OUT, p1_layed_out);
      nv.put(Database.KEY_P2_LAYED_OUT, p2_layed_out);
      nv.put(Database.KEY_RATED, rated);
      nv.put(Database.KEY_SHOTS_PER_TURN, shots_per_turn);
      nv.put(Database.KEY_T_LIMIT, t_limit);

      sqlite.update(Database.TB_GAMES, nv, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }

  public void updatePlayer(final int master_id, final String name, final int wins, final int losses, final int rating, final int last_login, final int bot)
  {
    if( open )
    {
      ContentValues nv = new ContentValues();
      nv.put(Database.KEY_MASTER_ID, master_id);
      nv.put(Database.KEY_NAME, name);
      nv.put(Database.KEY_WINS, wins);
      nv.put(Database.KEY_LOSSES, losses);
      nv.put(Database.KEY_RATING, rating);
      nv.put(Database.KEY_LAST_LOGIN, last_login);
      nv.put(Database.KEY_BOT, bot);

      sqlite.update(Database.TB_PLAYERS, nv, Database.KEY_MASTER_ID + " = " + master_id, null);
    }
  }
}
