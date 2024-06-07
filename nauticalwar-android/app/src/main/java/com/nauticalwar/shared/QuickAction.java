package com.nauticalwar.shared;

import android.content.Context;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;

import com.nauticalwar.nw.R;

public class QuickAction extends PopupWindows
{
  public interface OnActionItemClickListener
  {
    void onItemClick(int id, String title);
  }

  private View mRootView;
  private ImageView mArrowUp;
  private ImageView mArrowDown;
  private final LayoutInflater inflater;
  private ViewGroup mTrack;
  private ScrollView mScroller;
  private int id;

  private OnActionItemClickListener mListener;

  private static final int ANIM_GROW_FROM_LEFT = 1;
  private static final int ANIM_GROW_FROM_RIGHT = 2;
  private static final int ANIM_GROW_FROM_CENTER = 3;
  private static final int ANIM_REFLECT = 4;
  private static final int ANIM_AUTO = 5;

  private int mChildPos;
  private final int animStyle;

  public QuickAction(final Context context)
  {
    super(context);

    inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

    setRootViewId(R.layout.popup);

    animStyle = QuickAction.ANIM_AUTO;
    mChildPos = 0;
  }

  public void addActionItem(final ActionItem action)
  {
    final String title = action.getTitle();
    Drawable icon = action.getIcon();

    View container = inflater.inflate(R.layout.action_item, null);

    ImageView img = container.findViewById(R.id.iv_icon);
    TextView text = container.findViewById(R.id.tv_title);

    if( icon != null )
    {
      img.setImageDrawable(icon);
    }
    else
    {
      img.setVisibility(View.GONE);
    }

    if( title != null )
    {
      text.setText(title);
    }
    else
    {
      text.setVisibility(View.GONE);
    }

    container.setOnClickListener(new OnClickListener()
    {
      @Override
      public void onClick(final View v)
      {
        if( mListener != null )
        {
          mListener.onItemClick(id, title);
        }

        dismiss();
      }
    });

    container.setFocusable(true);
    container.setClickable(true);

    mTrack.addView(container, mChildPos);

    mChildPos++;
  }

  private void setAnimationStyle(final int screenWidth, final int requestedX, final boolean onTop)
  {
    int arrowPos = requestedX - mArrowUp.getMeasuredWidth() / 2;

    switch( animStyle )
    {
      case ANIM_GROW_FROM_LEFT:
        mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Left : R.style.Animations_PopDownMenu_Left);
        break;

      case ANIM_GROW_FROM_RIGHT:
        mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Right : R.style.Animations_PopDownMenu_Right);
        break;

      case ANIM_GROW_FROM_CENTER:
        mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Center : R.style.Animations_PopDownMenu_Center);
        break;

      case ANIM_REFLECT:
        mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Reflect : R.style.Animations_PopDownMenu_Reflect);
        break;

      case ANIM_AUTO:
        if( arrowPos <= screenWidth / 4 )
        {
          mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Left : R.style.Animations_PopDownMenu_Left);
        }
        else if( arrowPos > screenWidth / 4 && arrowPos < 3 * (screenWidth / 4) )
        {
          mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Center : R.style.Animations_PopDownMenu_Center);
        }
        else
        {
          mWindow.setAnimationStyle(onTop ? R.style.Animations_PopUpMenu_Right : R.style.Animations_PopDownMenu_Right);
        }

        break;
    }
  }

  public void setOnActionItemClickListener(final OnActionItemClickListener listener)
  {
    mListener = listener;
  }

  private void setRootViewId(final int id)
  {
    mRootView = inflater.inflate(id, null);
    mTrack = mRootView.findViewById(R.id.tracks);
    mArrowDown = mRootView.findViewById(R.id.arrow_down);
    mArrowUp = mRootView.findViewById(R.id.arrow_up);
    mScroller = mRootView.findViewById(R.id.scroller);

    setContentView(mRootView);
  }

  public void show(final View anchor)
  {
    preShow();

    id = anchor.getId();
    int xPos, yPos;

    int[] location = new int[2];

    anchor.getLocationOnScreen(location);

    Rect anchorRect = new Rect(location[0], location[1], location[0] + anchor.getWidth(), location[1] + anchor.getHeight());

    mRootView.setLayoutParams(new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
    mRootView.measure(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);

    int rootHeight = mRootView.getMeasuredHeight();
    int rootWidth = mRootView.getMeasuredWidth();

    DisplayMetrics displaymetrics = new DisplayMetrics();
    mWindowManager.getDefaultDisplay().getMetrics(displaymetrics);

    int screenWidth = displaymetrics.widthPixels;
    int screenHeight = displaymetrics.heightPixels;

    if( anchorRect.left + rootWidth > screenWidth )
    {
      xPos = anchorRect.left - (rootWidth - anchor.getWidth());
    }
    else
    {
      if( anchor.getWidth() > rootWidth )
      {
        xPos = anchorRect.centerX() - rootWidth / 2;
      }
      else
      {
        xPos = anchorRect.left;
      }
    }

    int dyTop = anchorRect.top;
    int dyBottom = screenHeight - anchorRect.bottom;

    boolean onTop = dyTop > dyBottom;

    if( onTop )
    {
      if( rootHeight > dyTop )
      {
        yPos = 15;
        LayoutParams l = mScroller.getLayoutParams();
        l.height = dyTop - anchor.getHeight();
      }
      else
      {
        yPos = anchorRect.top - rootHeight;
      }
    }
    else
    {
      yPos = anchorRect.bottom;

      if( rootHeight > dyBottom )
      {
        LayoutParams l = mScroller.getLayoutParams();
        l.height = dyBottom;
      }
    }

    showArrow(onTop ? R.id.arrow_down : R.id.arrow_up, anchorRect.centerX() - xPos);
    setAnimationStyle(screenWidth, anchorRect.centerX(), onTop);
    mWindow.showAtLocation(anchor, Gravity.NO_GRAVITY, xPos, yPos);
  }

  private void showArrow(final int whichArrow, final int requestedX)
  {
    final View showArrow = whichArrow == R.id.arrow_up ? mArrowUp : mArrowDown;
    final View hideArrow = whichArrow == R.id.arrow_up ? mArrowDown : mArrowUp;
    final int arrowWidth = mArrowUp.getMeasuredWidth();

    showArrow.setVisibility(View.VISIBLE);
    ViewGroup.MarginLayoutParams param = (ViewGroup.MarginLayoutParams) showArrow.getLayoutParams();
    param.leftMargin = requestedX - arrowWidth / 2;
    hideArrow.setVisibility(View.INVISIBLE);
  }
}
