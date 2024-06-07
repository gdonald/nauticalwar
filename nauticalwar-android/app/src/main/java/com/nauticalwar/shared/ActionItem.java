package com.nauticalwar.shared;

import android.graphics.drawable.Drawable;

public class ActionItem
{
  private Drawable icon;
  private String title;

  public ActionItem()
  {
  }

  public Drawable getIcon()
  {
    return icon;
  }

  public String getTitle()
  {
    return title;
  }

  public void setIcon(final Drawable i)
  {
    icon = i;
  }

  public void setTitle(final String t)
  {
    title = t;
  }
}
