package com.nauticalwar.shared;

import org.apache.http.conn.scheme.LayeredSocketFactory;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;

class EasySSLSocketFactory implements LayeredSocketFactory
{
  private static SSLContext createEasySSLContext() throws IOException
  {
    try
    {
      SSLContext context = SSLContext.getInstance("TLS");
      context.init(null, new TrustManager[]{new EasyX509TrustManager(null)}, null);
      return context;
    }
    catch( Exception e )
    {
      throw new IOException(e.getMessage());
    }
  }

  private SSLContext sslcontext = null;

  @Override
  public Socket connectSocket(final Socket sock, final String host, final int port, final InetAddress localAddress, int localPort, final HttpParams params) throws IOException
  {
    int connTimeout = HttpConnectionParams.getConnectionTimeout(params);
    int soTimeout = HttpConnectionParams.getSoTimeout(params);

    InetSocketAddress remoteAddress = new InetSocketAddress(host, port);
    SSLSocket sslsock = (SSLSocket) (sock != null ? sock : createSocket());

    if( localAddress != null || localPort > 0 )
    {
      if( localPort < 0 )
      {
        localPort = 0;
      }
      InetSocketAddress isa = new InetSocketAddress(localAddress, localPort);
      sslsock.bind(isa);
    }

    sslsock.connect(remoteAddress, connTimeout);
    sslsock.setSoTimeout(soTimeout);
    return sslsock;
  }

  @Override
  public Socket createSocket() throws IOException
  {
    return getSSLContext().getSocketFactory().createSocket();
  }

  @Override
  public Socket createSocket(final Socket socket, final String host, final int port, final boolean autoClose) throws IOException
  {
    return getSSLContext().getSocketFactory().createSocket(socket, host, port, autoClose);
  }

  @Override
  public boolean equals(final Object obj)
  {
    return obj != null && obj.getClass().equals(EasySSLSocketFactory.class);
  }

  private SSLContext getSSLContext() throws IOException
  {
    if( sslcontext == null )
    {
      sslcontext = EasySSLSocketFactory.createEasySSLContext();
    }
    return sslcontext;
  }

  @Override
  public int hashCode()
  {
    return EasySSLSocketFactory.class.hashCode();
  }

  @Override
  public boolean isSecure(final Socket socket) throws IllegalArgumentException
  {
    return true;
  }
}
