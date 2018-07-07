package com.nauticalwar.shared;

import com.nauticalwar.nw.R;

import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

class EasyX509TrustManager implements X509TrustManager
{
  private X509TrustManager standardTrustManager;

  EasyX509TrustManager(final KeyStore keystore) throws NoSuchAlgorithmException, KeyStoreException
  {
    super();
    TrustManagerFactory factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    factory.init(keystore);
    TrustManager[] trustmanagers = factory.getTrustManagers();
    if( trustmanagers.length == 0 )
    {
      throw new NoSuchAlgorithmException("no trust manager found");
    }
    standardTrustManager = (X509TrustManager) trustmanagers[0];
  }

  @Override
  public void checkClientTrusted(final X509Certificate[] certificates, final String authType) throws CertificateException
  {
    standardTrustManager.checkClientTrusted(certificates, authType);
  }

  @Override
  public void checkServerTrusted(final X509Certificate[] certificates, final String authType) throws CertificateException
  {
    if( certificates != null && certificates.length == 1 )
    {
      certificates[0].checkValidity();
    }
//    else
//    {
//      standardTrustManager.checkServerTrusted(certificates, authType);
//    }
  }

  @Override
  public X509Certificate[] getAcceptedIssuers()
  {
    return standardTrustManager.getAcceptedIssuers();
  }
}
