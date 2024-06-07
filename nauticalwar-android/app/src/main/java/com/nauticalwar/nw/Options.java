package com.nauticalwar.nw;

import android.app.Activity;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Intent;
import android.media.AudioManager;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.Preference.OnPreferenceChangeListener;
import android.preference.Preference.OnPreferenceClickListener;
import android.preference.PreferenceFragment;
import android.view.KeyEvent;

import com.nauticalwar.shared.MyApplication;

public class Options extends Activity
{
  public static class OptionsFragment extends PreferenceFragment
  {
    MyApplication app;
    Preference doSound, doVibrate, waterColor, doNotify;
    Preference doNotifySound, doNotifyVibrate, doNotifyBlink;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
      super.onCreate(savedInstanceState);
      addPreferencesFromResource(R.xml.options);

      app = (MyApplication) getActivity().getApplication();

      doSound = findPreference("doSound");
      doSound.setOnPreferenceClickListener(doSoundClickListener);

      doVibrate = findPreference("doVibrate");
      doVibrate.setOnPreferenceClickListener(doVibrateClickListener);

      waterColor = findPreference("waterColor");
      waterColor.setOnPreferenceChangeListener(waterOnPreferenceChangeListener);

      doNotify = findPreference("doNotify");
      doNotify.setOnPreferenceChangeListener(doNotifyOnPreferenceChangeListener);

      doNotifySound = findPreference("doNotifySound");
      doNotifyVibrate = findPreference("doNotifyVibrate");
      doNotifyBlink = findPreference("doNotifyBlink");

      if( app.getSettings().getBoolean("doNotify", false) )
      {
        doNotifySound.setEnabled(true);
        doNotifyVibrate.setEnabled(true);
        doNotifyBlink.setEnabled(true);
      }
      else
      {
        doNotifySound.setEnabled(false);
        doNotifyVibrate.setEnabled(false);
        doNotifyBlink.setEnabled(false);
      }
    }

    private final OnPreferenceClickListener doSoundClickListener = new OnPreferenceClickListener()
    {
      @Override
      public boolean onPreferenceClick(final Preference preference)
      {
        app.sndClick();
        return true;
      }
    };

    private final OnPreferenceClickListener doVibrateClickListener = new OnPreferenceClickListener()
    {
      @Override
      public boolean onPreferenceClick(final Preference preference)
      {
        app.sndClick();
        return true;
      }
    };

    private final OnPreferenceChangeListener waterOnPreferenceChangeListener = new OnPreferenceChangeListener()
    {
      @Override
      public boolean onPreferenceChange(final Preference preference, final Object newValue)
      {
        app.unsetWaterBD();
        return true;
      }
    };

    private final OnPreferenceChangeListener doNotifyOnPreferenceChangeListener = new OnPreferenceChangeListener()
    {
      @Override
      public boolean onPreferenceChange(final Preference preference, final Object newValue)
      {
        boolean b = (Boolean) newValue;

        if( b )
        {
          app.doBindService();
          doNotifySound.setEnabled(true);
          doNotifyVibrate.setEnabled(true);
          doNotifyBlink.setEnabled(true);
        }
        else
        {
          app.doUnbindService();
          doNotifySound.setEnabled(false);
          doNotifyVibrate.setEnabled(false);
          doNotifyBlink.setEnabled(false);
        }

        return true;
      }
    };
  }

  private MyApplication app;

  private void goHome()
  {
    Intent i = new Intent(this, Home.class);
    startActivity(i);
    finish();
  }

  @Override
  protected void onCreate(final Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    app = (MyApplication) getApplication();

    FragmentManager mFragmentManager = getFragmentManager();
    FragmentTransaction mFragmentTransaction = mFragmentManager.beginTransaction();
    OptionsFragment mPrefsFragment = new OptionsFragment();
    mFragmentTransaction.replace(android.R.id.content, mPrefsFragment);
    mFragmentTransaction.commit();

    setVolumeControlStream(AudioManager.STREAM_MUSIC);
  }

  @Override
  public boolean onKeyDown(final int keyCode, final KeyEvent event)
  {
    if( keyCode == KeyEvent.KEYCODE_BACK )
    {
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
}
