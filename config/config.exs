import Config

config :ueberauth, Ueberauth,
  providers: [
    fastmail:
      {Ueberauth.Strategy.Close,
       [
         oauth2_module: OAuthMock
       ]}
  ]
