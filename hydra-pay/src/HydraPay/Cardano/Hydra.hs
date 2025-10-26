
getAddressUTxO :: (MonadIO m, HasLogger a, HasHydraHeadManager a, ToAddress b) => a -> Int32 -> b -> m (Either Text (Api.UTxO Api.BabbageEra))
getAddressUTxO a hid b = runExceptT $ do
  runningHeadVar <- ExceptT $ getRunningHead a hid
  runningHead <- liftIO $ readTMVarIO runningHeadVar
  let node = unsafeAnyNode runningHead
  utxo <- ExceptT $ getUTxOFromNode node
  pure $ filterUTxOByAddress (toAddress b) utxo
