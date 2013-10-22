{
{-# OPTIONS -w #-}
module Language.EWE.Parser(pEWE) where

import Language.EWE.Token(Tkns,Tkn(..))
import Language.EWE.Scanner
import Language.EWE.AbsSyn
}

%name parse
%tokentype { Tkn }
%error     { parseError }
%monad { Alex } 
%lexer { lexwrap } { TknEOF }

%token int        { TknInt $$ }
       str        { TknStr $$ }  
--       label      { TknLabel $$ }
       id         { TknId $$ }
       ':='       { TknAssgn }
       ':'        { TknColon }
       '('        { TknLPar  }
       ')'        { TknRPar  }
       '['        { TknLBrk  }
       ']'        { TknRBrk  }
       ','        { TknComma }
       '+'        { TknOper '+' }
       '-'        { TknOper '-' }
       '*'        { TknOper '*' }
       '/'        { TknOper '/' }
       '%'        { TknOper '%' }
       '<>'       { TknCond "<>" }
       '='        { TknCond "=" }
       '<'        { TknCond "<" }
       '<='       { TknCond "<=" }
       '>'        { TknCond ">" }
       '>='       { TknCond ">=" }
       'PC'       { TknResWrd "PC" }
       'M'        { TknResWrd "M" }
       'readInt'  { TknResWrd "readInt" }
       'writeInt' { TknResWrd "writeInt" }
       'readStr'  { TknResWrd "readStr" }
       'writeStr' { TknResWrd "writeStr" }
       'goto'     { TknResWrd "goto" }
       'if'        { TknResWrd "if" }
       'then'     { TknResWrd "then" }
       'halt'     { TknResWrd "halt" }
       'break'    { TknResWrd "break" }
       'equ'      { TknResWrd "equ" }
%%

EweProg : Executable Equates { Prg $1 $2 }

Executable : LabelInstr              { [$1] }
           | LabelInstr Executable   { $1:$2 }

LabelInstr : id ':' LabelInstr        { addLabel $1 $3 }
           | Instr                   { Stmt [] $1 }

Instr : MemRef ':=' int                           { IMMI $1 $3  }
      | MemRef ':=' str                           { IMMS $1 $3  }
      | MemRef ':=' 'PC' '+' int                  { IMRPC $1 $5 }
      | 'PC'   ':=' MemRef                        { SPC $3 }
      | MemRef ':=' MemRef                        { IMMM $1 $3 }
      | MemRef ':=' MemRef '+' MemRef             { IAdd $1 $3 $5 }
      | MemRef ':=' MemRef '-' MemRef             { ISub $1 $3 $5 }
      | MemRef ':=' MemRef '*' MemRef             { IMul $1 $3 $5 }
      | MemRef ':=' MemRef '/' MemRef             { IDiv $1 $3 $5 }
      | MemRef ':=' MemRef '%' MemRef             { IMod $1 $3 $5 }
      | MemRef ':=' 'M' '[' MemRef '+' int ']'    { IMRI $1 $5 $7 }
      | 'M' '[' MemRef '+' int ']' ':=' MemRef    { IMMR $3 $5 $8 }
      | 'readInt' '(' MemRef ')'                  { IRI $3 }
      | 'writeInt' '(' MemRef ')'                 { IWI $3 }
      | 'readStr' '(' MemRef ',' MemRef ')'       { IRS $3 $5 }  
      | 'writeStr' '(' MemRef ')'                 { IWS $3 }
      | 'goto' int                                { IGI $2 }
      | 'goto' id                                 { IGS $2 }
      | 'if' MemRef Cond MemRef 'then' 'goto' int { IFI $2 $3 $4 $7 }
      | 'if' MemRef Cond MemRef 'then' 'goto' id  { IFS $2 $3 $4 $7 }
      | 'halt'                                    { IH }
      | 'break'                                   { IB }

Equates :                                         { [] }
        | 'equ' id 'M' '[' int ']' Equates        { ($2,$5):$7 }

MemRef : 'M' '[' int ']'                          { MRefI $3 }
       | id                                       { MRefId $1 }

Cond : '<='                                       { CLET }
     | '<'                                        { CLT }
     | '>='                                       { CGET }
     | '>'                                        { CGT }
     | '='                                        { CE }
     | '<>'                                       { CNE }

{

lexwrap :: (Tkn -> Alex a) -> Alex a
lexwrap cont = do
   t <- alexMonadScan
   cont t

addLabel :: String -> Stmt -> Stmt
addLabel s (Stmt ss i) = Stmt (s:ss) i

parseError :: Tkn -> Alex a
parseError t = do
  (l,c) <- getPosn
  fail (show l ++ ":" ++ show c ++ ": Parser error on Token: " ++ show t ++ "\n")

pEWE :: String -> Either String Prog
pEWE s = runAlex s parse
}

