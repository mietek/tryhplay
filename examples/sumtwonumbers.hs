{-# LANGUAGE  DeriveDataTypeable #-}
module Main where
import Haste
import Haste.DOM(withElem)
import Haste.Foreign
import Haste.Graphics.Canvas
import Haste.HPlay.View
import Haste.HPlay.Cell as Cell
import Control.Applicative
import Control.Monad
import Control.Monad.IO.Class
import Data.Monoid
import Data.Typeable
import Prelude hiding (div,all,id)
import qualified Data.Map as V
import Data.Maybe
import Data.List(isInfixOf)


main= runBody $
    p  "This widget sum two numbers and append the result. Using applicative and monadic expressions" ++>
  (p <<< do
     r <- (+) <$> fromStr "first number"  ++> br
                   ++> inputInt Nothing `fire` OnKeyUp  <++ br
              <*> fromStr "second number " ++> br
                   ++> inputInt Nothing `fire` OnKeyUp  <++ br
     p <<< fromStr "result: " ++>  b (show r) ++> return())

