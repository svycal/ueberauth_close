import Config

config :ueberauth, Ueberauth,
  providers: [
    close:
      {Ueberauth.Strategy.Close,
       [
         oauth2_module: OAuthMock
       ]}
  ]
