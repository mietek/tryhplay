{-#LANGUAGE OverloadedStrings, DeriveDataTypeable #-}
module Main where

import MFlow.Wai.Blaze.Html.All
import Haste.Compiler
import Data.Default
import Prelude hiding (id,div,head)
import qualified Data.List as L
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.String
import Data.TCache.DefaultPersistence
import Data.TCache.IndexText

import System.Directory
import qualified Data.ByteString.Lazy.Char8 as B
import Data.Typeable
import Data.Monoid
import Text.Blaze.Html5.Attributes as At hiding (step,name)
import qualified Data.Text.Lazy as TL
import Control.Monad
import Control.Shell

import Debug.Trace

--(!>)= flip trace

projects= "./examples/"

data Examples= Examples [String] deriving (Read,Show,Typeable)
instance Indexable Examples where key = const "examples"
instance Serializable Examples where
  serialize = B.pack . show
  deserialize = read . B.unpack

listExamples (Examples list)= list

main= do
  indexList listExamples (map TL.pack )
  examples <- atomically $ newDBRef $ Examples ["example.hs","todo.hs","sumtwonumbers.hs"]

  setFilesPath projects
  let dontcare ="updateme"
  runNavigation "try" . transientNav $ do
    page . pageFlow "try" $ do
          Examples exampleList <- liftIO $ atomically $ readDBRef examples
                                  `onNothing` error "examples empty"

          example <- wform $ b  "you can load also one of these examples "
                     ++> firstOf[submitButton e  <++ " " | e <- exampleList]
                     <|> return "none"

          extext <- if example /= "none" then liftIO $ TIO.readFile $ projects ++ example else return ""

          (name,r) <- wform $ p <<< ( (,) <$> getString (Just example)
                                  <*> getMultilineText extext <! [("style","width:100%;height:300")]
                        <++ br
                        <** submitButton "compile"
                        <++ br)


          let haskell=  T.unpack r
              hsfile =  name ++ ".hs"
          liftIO $ writeFile  (projects ++ hsfile) haskell

          let html =   projects ++ name ++ ".html"
          exist <- liftIO $ doesFileExist html
          when exist . liftIO $ removeFile html
          r <- liftIO . shell $ inDirectory projects $ genericRun "/app/.cabal/bin/hastec" [hsfile,"--output-html"] ""
--          r <- liftIO . shell $ inDirectory projects $ genericRun "/home/user/.cabal/bin/hastec" [hsfile,"--output-html"] ""
          case r of
            Left errs -> fromStr ("*******Failure: not found hastec"++  errs) ++> empty
            Right (r,out,err) ->
              case r of
                  True  -> do
                    liftIO . atomically . writeDBRef examples . Examples . L.nub $ (name++".hs"):exampleList
                    (a  ! href  (fromString("/"++name++".html")) $ "execute") ++> empty
                  False -> fromStr err ++> empty

