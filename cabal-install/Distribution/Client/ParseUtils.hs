-----------------------------------------------------------------------------
-- |
-- Module      :  Distribution.Client.ParseUtils
-- Maintainer  :  cabal-devel@haskell.org
-- Portability :  portable
--
-- Parsing utilities.
-----------------------------------------------------------------------------

module Distribution.Client.ParseUtils ( parseFields, ppFields, ppSection )
       where

import Distribution.ParseUtils
         ( FieldDescr(..), ParseResult(..), warning, lineNo )
import qualified Distribution.ParseUtils as ParseUtils
         ( Field(..) )

import Control.Monad    ( foldM )
import Text.PrettyPrint ( (<>), (<+>), ($$) )
import qualified Data.Map as Map
import qualified Text.PrettyPrint as Disp
         ( Doc, text, colon, vcat, isEmpty, nest )

--FIXME: replace this with something better
parseFields :: [FieldDescr a] -> a -> [ParseUtils.Field] -> ParseResult a
parseFields fields initial = foldM setField initial
  where
    fieldMap = Map.fromList
      [ (name, f) | f@(FieldDescr name _ _) <- fields ]
    setField accum (ParseUtils.F line name value) =
      case Map.lookup name fieldMap of
        Just (FieldDescr _ _ set) -> set line value accum
        Nothing -> do
          warning $ "Unrecognized field " ++ name ++ " on line " ++ show line
          return accum
    setField accum f = do
      warning $ "Unrecognized stanza on line " ++ show (lineNo f)
      return accum

-- | This is a customised version of the function from Cabal that also prints
-- default values for empty fields as comments.
--
ppFields :: [FieldDescr a] -> a -> a -> Disp.Doc
ppFields fields def cur = Disp.vcat [ ppField name (getter def) (getter cur)
                                    | FieldDescr name getter _ <- fields]

ppField :: String -> Disp.Doc -> Disp.Doc -> Disp.Doc
ppField name def cur
  | Disp.isEmpty cur = Disp.text "--" <+> Disp.text name <> Disp.colon <+> def
  | otherwise        =                    Disp.text name <> Disp.colon <+> cur

ppSection :: String -> String -> [FieldDescr a] -> a -> a -> Disp.Doc
ppSection name arg fields def cur =
     Disp.text name <+> Disp.text arg
  $$ Disp.nest 2 (ppFields fields def cur)
