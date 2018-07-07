package com.nauticalwar.fragments;

import android.app.Dialog;
import android.app.DialogFragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.TextView;

import com.nauticalwar.nw.R;

public class WaitDialog extends DialogFragment
{
  private String message;

  public WaitDialog()
  {
  }

  @Override
  public void setArguments(Bundle args)
  {
    super.setArguments(args);
    message = args.getString("message");
  }

  @Override
  public Dialog onCreateDialog(Bundle savedInstanceState)
  {
    Dialog dialog = super.onCreateDialog(savedInstanceState);
    Window window = dialog.getWindow();

    if( window != null )
    {
      window.requestFeature(Window.FEATURE_NO_TITLE);
    }

    return dialog;
  }

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState)
  {
    View view = inflater.inflate(R.layout.wait_dialog, container, false);
    TextView messageView = view.findViewById(R.id.messageView);
    messageView.setText(message);
    return view;
  }
}
