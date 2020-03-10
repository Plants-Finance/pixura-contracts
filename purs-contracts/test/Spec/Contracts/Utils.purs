module Test.Spec.Contracts.Utils where

import Prelude
import Chanterelle.Internal.Deploy (DeployReceipt)
import Chanterelle.Internal.Types (NoArgs)
import Control.Monad.Error.Class (class MonadThrow, throwError)
import Data.Either (Either(..))
import Data.Lens ((?~))
import Data.Maybe (Maybe(..), fromJust)
import Deploy.Contracts.SuperRareV2 as SuperRareV2
import Effect.Aff (Aff, Error, error)
import Effect.Aff.AVar (AVar, empty, tryRead)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Exception.Unsafe (unsafeThrow)
import Network.Ethereum.Core.BigNumber (BigNumber, decimal, embed, parseBigNumber)
import Network.Ethereum.Web3 (Address, CallError, Provider, TransactionOptions, UIntN, Web3, _from, _gas, _gasPrice, defaultTransactionOptions, runWeb3, uIntNFromBigNumber)
import Network.Ethereum.Web3.Solidity.Sizes (S256, s256)
import Network.Ethereum.Web3.Types (NoPay)
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck (arbitrary)
import Test.QuickCheck.Gen (Gen, randomSample')
import Test.Spec.Assertions (shouldEqual)

type TestEnv
  = { supeRare :: AVar (DeployReceipt NoArgs)
    , superRareV2 :: AVar (DeployReceipt SuperRareV2.SuperRareV2)
    , superRareMarketAuction :: AVar (DeployReceipt NoArgs)
    , superRareMarketAuctionV2 :: AVar (DeployReceipt NoArgs)
    , supeRareTokens :: AVar (Array (UIntN S256))
    , superRareV2Tokens :: AVar (Array (UIntN S256))
    , provider :: AVar Provider
    , accounts :: AVar (Array Address)
    , primaryAccount :: AVar Address
    }

init :: Aff TestEnv
init =
  { supeRare: _
  , superRareV2: _
  , superRareMarketAuction: _
  , superRareMarketAuctionV2: _
  , supeRareTokens: _
  , superRareV2Tokens: _
  , provider: _
  , accounts: _
  , primaryAccount: _
  }
    <$> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty
    <*> liftAff empty

readOrFail :: forall m a. (MonadAff m) => AVar a -> m a
readOrFail x = do
  mx <- liftAff $ tryRead x
  pure $ unsafePartial $ fromJust mx

mkTokenUris :: forall m. MonadEffect m => Int -> m (Array String)
mkTokenUris n = map (map show) $ liftEffect $ randomSample' n (arbitrary :: Gen Int)

defaultTxOpts :: Address -> TransactionOptions NoPay
defaultTxOpts primaryAccount =
  let
    limit = unsafePartial fromJust $ parseBigNumber decimal "6712388"

    price = unsafePartial fromJust $ parseBigNumber decimal "10000000000"
  in
    defaultTransactionOptions # _from ?~ primaryAccount
      # _gas
      ?~ limit
      # _gasPrice
      ?~ price

uInt256FromBigNumber :: BigNumber -> UIntN S256
uInt256FromBigNumber n = case uIntNFromBigNumber s256 n of
  Nothing -> (unsafeThrow $ "Invalid BigNumber " <> show n <> " to build UInt256")
  Just n' -> n'

intToUInt256 :: Int -> UIntN S256
intToUInt256 = uInt256FromBigNumber <<< embed

web3Test ::
  forall m.
  MonadAff m =>
  MonadThrow Error m => Provider -> Web3 Unit -> m Unit
web3Test prov f = do
  res <- liftAff $ runWeb3 prov f
  res `shouldEqual` Right unit

throwOnCallError :: forall a m. MonadThrow Error m => m (Either CallError a) -> m a
throwOnCallError f =
  f
    >>= case _ of
        Left cerr -> throwError $ error $ show cerr
        Right x -> pure x
