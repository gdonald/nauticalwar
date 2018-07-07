package com.nauticalwar.shared;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpVersion;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.protocol.ClientContext;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.params.ConnManagerPNames;
import org.apache.http.conn.params.ConnPerRouteBean;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.SingleClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.CoreProtocolPNames;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HTTP;
import org.apache.http.protocol.HttpContext;
import org.apache.http.util.EntityUtils;

import java.util.List;

public class MyHTTP
{
  private HttpEntity entity;
  private final HttpContext http_context;
  private final HttpClient httpclient;
  private HttpResponse response;

  public MyHTTP(final BasicCookieStore cookieStore)
  {
    SchemeRegistry schemeRegistry = new SchemeRegistry();
    schemeRegistry.register(new Scheme("http", PlainSocketFactory.getSocketFactory(), 80));
    schemeRegistry.register(new Scheme("https", new EasySSLSocketFactory(), 443));

    HttpParams params = new BasicHttpParams();

    int timeout_connection = 10000;
    HttpConnectionParams.setConnectionTimeout(params, timeout_connection);

    int timeout_socket = 0;
    HttpConnectionParams.setSoTimeout(params, timeout_socket);

    params.setParameter(ConnManagerPNames.MAX_TOTAL_CONNECTIONS, 30);
    params.setParameter(ConnManagerPNames.MAX_CONNECTIONS_PER_ROUTE, new ConnPerRouteBean(30));
    params.setParameter(CoreProtocolPNames.USE_EXPECT_CONTINUE, false);
    HttpProtocolParams.setVersion(params, HttpVersion.HTTP_1_1);

    ClientConnectionManager cm = new SingleClientConnManager(params, schemeRegistry);

    httpclient = new DefaultHttpClient(cm, params);
    http_context = new BasicHttpContext();
    http_context.setAttribute(ClientContext.COOKIE_STORE, cookieStore);
  }

  public String doGet(final String url)
  {
    HttpGet get = new HttpGet(url);
    String s = null;

    try
    {
      response = httpclient.execute(get, http_context);
      entity = response.getEntity();
      s = EntityUtils.toString(entity).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    return s;
  }

  public String doPost(final String url, final List< NameValuePair > params)
  {
    HttpPost post = new HttpPost(url);
    String s = null;

    try
    {
      post.setEntity(new UrlEncodedFormEntity(params, HTTP.UTF_8));
      response = httpclient.execute(post, http_context);
      entity = response.getEntity();
      s = EntityUtils.toString(entity).trim();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    return s;
  }
}
