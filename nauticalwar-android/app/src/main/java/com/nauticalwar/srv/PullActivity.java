package com.nauticalwar.srv;

import com.nauticalwar.shared.MyApplication;

import java.util.TimerTask;

class PullActivity extends TimerTask
{
  private final MyApplication app;

  PullActivity(final MyApplication a)
  {
    app = a;
  }

  @Override
  public void run()
  {
    new Thread(new Runnable()
    {
      @Override
      public void run()
      {
        app.doGetActivity();
      }
    }).start();
  }
}
