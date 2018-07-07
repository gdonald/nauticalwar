package com.nauticalwar.shared;

import android.graphics.drawable.Drawable;

import org.json.JSONException;
import org.json.JSONObject;

public class Ship
{
  private static final String[] SHIPS = {"Carrier", "Battleship", "Destroyer", "Submarine", "Patrol Boat"};
  private static final int[] SHIP_SIZES = {5, 4, 3, 3, 2};

  private final MyApplication app;
  private final int type;
  private int col;
  private int row;
  private boolean vertical;

  Ship(final MyApplication a, final int t)
  {
    app = a;
    type = t;
    col = -1;
    row = -1;
  }

  public Drawable getBD()
  {
    switch( type )
    {
      case 0:
        return vertical ? app.getShipCarrierVerticalBD(this) : app.getShipCarrierHorizontalBD(this);

      case 1:
        return vertical ? app.getShipBattleshipVerticalBD(this) : app.getShipBattleshipHorizontalBD(this);

      case 2:
        return vertical ? app.getShipDestroyerVerticalBD(this) : app.getShipDestroyerHorizontalBD(this);

      case 3:
        return vertical ? app.getShipSubmarineVerticalBD(this) : app.getShipSubmarineHorizontalBD(this);

      case 4:
        return vertical ? app.getShipPTBoatVerticalBD(this) : app.getShipPTBoatHorizontalBD(this);
    }

    return null;
  }

  public int getCol()
  {
    return col;
  }

  public String getColRow()
  {
    return col + "," + row;
  }

  public int getLength()
  {
    return Ship.SHIP_SIZES[type];
  }

  public int getPixelHeight()
  {
    if( isVertical() )
    {
      return (int) (getLength() * app.getBasicShipSize());
    }
    else
    {
      return (int) app.getBasicShipSize();
    }
  }

  public int getPixelWidth()
  {
    if( isVertical() )
    {
      return (int) app.getBasicShipSize();
    }
    else
    {
      return (int) (getLength() * app.getBasicShipSize());
    }
  }

  private String getVertical()
  {
    return vertical ? "1" : "0";
  }

  public int getRow()
  {
    return row;
  }

  public int getType()
  {
    return type;
  }

  public boolean isHit(final int c, final int r)
  {
    if( row < 0 )
    {
      return false;
    }

    if( col < 0 )
    {
      return false;
    }

    int i;

    if( vertical )
    {
      if( c == col )
      {
        for( i = row; i < row + getLength(); i++ )
        {
          if( i == r )
          {
            return true;
          }
        }
      }
    }
    else
    {
      if( r == row )
      {
        for( i = col; i < col + getLength(); i++ )
        {
          if( i == c )
          {
            return true;
          }
        }
      }
    }

    return false;
  }

  public boolean isVertical()
  {
    return vertical;
  }

  public void setCol(int c)
  {
    if( c < 0 )
    {
      c = 0;
    }

    if( c > 9 )
    {
      c = 9;
    }

    if( !vertical )
    {
      if( c > 10 - getLength() )
      {
        c = 10 - getLength();
      }
    }

    col = c;
  }

  public void setPosition(final int c, final int r, final boolean v)
  {
    setCol(c);
    setRow(r);
    setVertical(v);
  }

  public void setRow(int r)
  {
    if( r < 0 )
    {
      r = 0;
    }

    if( r > 9 )
    {
      r = 9;
    }

    if( vertical )
    {
      if( r > 10 - getLength() )
      {
        r = 10 - getLength();
      }
    }

    row = r;
  }

  public void setVertical(final boolean v)
  {
    vertical = v;
    setRow(row);
    setCol(col);
  }

  public JSONObject toJSON()
  {
    JSONObject o = new JSONObject();

    try
    {
      o.put("name", SHIPS[getType()]);
    }
    catch( JSONException e )
    {
      e.printStackTrace();
    }

    try
    {
      o.put("x", getCol());
    }
    catch( JSONException e )
    {
      e.printStackTrace();
    }

    try
    {
      o.put("y", getRow());
    }
    catch( JSONException e )
    {
      e.printStackTrace();
    }

    try
    {
      o.put("vertical", getVertical());
    }
    catch( JSONException e )
    {
      e.printStackTrace();
    }

    return o;
  }
}
