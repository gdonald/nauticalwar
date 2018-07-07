package com.nauticalwar.shared;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.ViewGroup.LayoutParams;
import android.view.WindowManager;
import android.widget.PopupWindow;

class PopupWindows
{
  final PopupWindow mWindow;
  private View mRootView;
  final WindowManager mWindowManager;

  PopupWindows(final Context context)
  {
    mWindow = new PopupWindow(context);
    mWindow.setTouchInterceptor(new OnTouchListener()
    {
      @SuppressLint("ClickableViewAccessibility")
      @Override
      public boolean onTouch(final View v, final MotionEvent event)
      {
        if( event.getAction() == MotionEvent.ACTION_OUTSIDE )
        {
          mWindow.dismiss();
          return true;
        }

        return false;
      }
    });

    mWindowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
  }

  void dismiss()
  {
    mWindow.dismiss();
  }

  void preShow()
  {
    if( mRootView == null )
    {
      throw new IllegalStateException("setContentView was not called with a view to display.");
    }

    mWindow.setBackgroundDrawable(null);
    mWindow.setWidth(LayoutParams.WRAP_CONTENT);
    mWindow.setHeight(LayoutParams.WRAP_CONTENT);
    mWindow.setTouchable(true);
    mWindow.setFocusable(true);
    mWindow.setOutsideTouchable(true);
    mWindow.setContentView(mRootView);
  }

  void setContentView(final View root)
  {
    mRootView = root;
    mWindow.setContentView(root);
  }
}
