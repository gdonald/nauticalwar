package com.nauticalwar.shared;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class Fleet
{
  private Ship ships[];
  private final MyApplication app;

  public Fleet(final MyApplication a)
  {
    app = a;
    buildNewFleet();
  }

  public Fleet(final MyApplication a, final JSONArray layouts)
  {
    app = a;
    buildNewFleet(layouts);
  }

  public void buildNewFleet()
  {
    ships = new Ship[5];

    ships[0] = new Ship(app, 0);
    ships[0].setPosition(1, 1, true);

    ships[1] = new Ship(app, 1);
    ships[1].setPosition(2, 7, false);

    ships[2] = new Ship(app, 2);
    ships[2].setPosition(5, 3, true);

    ships[3] = new Ship(app, 3);
    ships[3].setPosition(7, 6, true);

    ships[4] = new Ship(app, 4);
    ships[4].setPosition(6, 1, false);
  }

  private void buildNewFleet(final JSONArray layouts)
  {
    ships = new Ship[layouts.length()];

    JSONObject layout;
    int id, vertical, x, y;

    for( int i = 0; i < layouts.length(); i++ )
    {
      try
      {
        layout = layouts.getJSONObject(i);
      }
      catch( JSONException e )
      {
        layout = null;
        e.printStackTrace();
      }

      if( layout != null )
      {
        try
        {
          id = layout.getInt("ship_id");
        }
        catch( JSONException e )
        {
          id = 0;
          e.printStackTrace();
        }

        try
        {
          vertical = layout.getInt("vertical");
        }
        catch( JSONException e )
        {
          vertical = 0;
          e.printStackTrace();
        }

        try
        {
          x = layout.getInt("x");
        }
        catch( JSONException e )
        {
          x = 0;
          e.printStackTrace();
        }

        try
        {
          y = layout.getInt("y");
        }
        catch( JSONException e )
        {
          y = 0;
          e.printStackTrace();
        }

        ships[i] = new Ship(app, id);
        ships[i].setVertical(vertical == 1);
        ships[i].setCol(x);
        ships[i].setRow(y);
      }
    }
  }

  public Ship getShipAtLocation(final int c, final int r)
  {
    if( ships == null )
    {
      return null;
    }

    for( Ship s : ships )
    {
      if( s.getCol() == c && s.getRow() == r )
      {
        return s;
      }
    }

    return null;
  }

  public Ship getShipAtLocation(final String selectedShip)
  {
    if( selectedShip != null && selectedShip.contains(",") )
    {
      String[] parts = selectedShip.split(",");

      if( parts.length == 2 )
      {
        int c = -1;
        int r = -1;

        try
        {
          c = Integer.valueOf(parts[0]);
          r = Integer.valueOf(parts[1]);
        }
        catch( Exception e )
        {
          e.printStackTrace();
        }

        if( c > -1 && r > -1 )
        {
          for( Ship s : ships )
          {
            if( s.getCol() == c && s.getRow() == r )
            {
              return s;
            }
          }
        }
      }
    }

    return null;
  }

  public Ship getShipAtLocation(final String c, final String r)
  {
    return getShipAtLocation(Integer.valueOf(c), Integer.valueOf(r));
  }

  public boolean hasOverlap()
  {
    int x;

    for( Ship s1 : ships )
    {
      for( Ship s2 : ships )
      {
        if( s1.getType() == s2.getType() )
        {
          continue;
        }
        else if( s1.getColRow().contains(s2.getColRow()) )
        {
          return true;
        }

        if( s1.isVertical() )
        {
          for( x = s1.getRow(); x < s1.getLength() + s1.getRow(); x++ )
          {
            if( s2.isHit(s1.getCol(), x) )
            {
              return true;
            }
          }
        }
        else
        {
          for( x = s1.getCol(); x < s1.getLength() + s1.getCol(); x++ )
          {
            if( s2.isHit(x, s1.getRow()) )
            {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  public JSONObject toJSON()
  {
    JSONObject o = new JSONObject();
    JSONArray shipsArray = new JSONArray();

    for( Ship s : ships )
    {
      shipsArray.put(s.toJSON());
    }

    try
    {
      o.put("ships", shipsArray);
    }
    catch( JSONException e )
    {
      e.printStackTrace();
    }

    return o;
  }
}
