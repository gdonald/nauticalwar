package com.nauticalwar.srv;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import com.nauticalwar.shared.MyApplication;

import java.util.Timer;
import java.util.TimerTask;

public class MyService extends Service
{
  class getEventsTask extends TimerTask
  {
    @Override
    public void run()
    {
      boolean doNotify = app.getSettings().getBoolean("doNotify", false);

      if( doNotify )
      {
        new PullActivity(app).run();
      }
      else
      {
        cancel();
      }
    }
  }

  public class LocalBinder extends Binder
  {
    public MyService getService()
    {
      return MyService.this;
    }
  }

  private static final int ONE_SECOND = 1000;
  private static final int ONE_MINUTE = 60 * MyService.ONE_SECOND;

  private final IBinder mBinder = new LocalBinder();
  private MyApplication app;

  private void addTimers()
  {
    Timer pullEventsTimer = new Timer();
    pullEventsTimer.schedule(new getEventsTask(), 2 * MyService.ONE_SECOND, 15 * MyService.ONE_MINUTE);
  }

  @Override
  public IBinder onBind(final Intent intent)
  {
    return mBinder;
  }

  @Override
  public void onCreate()
  {
    app = (MyApplication) getApplication();
  }

  @Override
  public int onStartCommand(final Intent intent, final int flags, final int startId)
  {
    addTimers();
    return Service.START_NOT_STICKY;
  }

}
