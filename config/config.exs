import Config

config :ueberauth, Ueberauth,
  providers: [
    closecrm:
      {Ueberauth.Strategy.Close,
       [
         oauth2_module: OAuthMock
       ]}
  ]
