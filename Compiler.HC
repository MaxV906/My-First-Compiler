
#define TOKEN_NULL 0
#define TOKEN_NUM 1
#define TOKEN_OP 2
#define TOKEN_BR 3
#define TOKEN_UNKNOWN 4

asm {

  _ADD::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	ADD RAX, RDX

	RET1 16

  _SUB::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	SUB RAX, RDX

	RET1 16

  _MUL::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	MUL RDX

	RET1 16

  _OR::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	OR RAX, RDX

	RET1 16

  _XOR::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	XOR RAX, RDX

	RET1 16

  _AND::

	MOV RAX, 8[RSP]
	MOV RDX, 16[RSP]

	OR RAX, RDX

	RET1 16

  _NOT::

	MOV RDX, 8[RSP]
	XOR RAX, RAX
	TEST RDX, RDX

	SETE AL


	RET1 8

  _TO_BOOL::

	MOV RDX, 9[RSP]
	XOR RAX, RAX
	TEST RDX, RDX

	SETNE AL

	RET1 8

}

_extern _ADD I64 Add(I64 a, I64 b);
_extern _SUB I64 Sub(I64 a, I64 b);
_extern _MUL I64 Mul(I64 a, I64 b);
_extern _OR I64 Or(I64 a, I64 b);
_extern _XOR I64 XOr(I64 a, I64 b);
_extern _AND I64 And(I64 a, I64 b);
_extern _NOT I64 Not(I64 a);
_extern _TO_BOOL I64 Boolean(I64 a);

class Token {

  Token *next;
  I64 type;
  I64 value;
  I64 txt_len;
  U8 *txt;

};

class Lexer {

  I64 cursor;
  I64 content_len;
  U8 *content;

};

Bool IsNum(U8 char) return (char >= '0' && char <= '9');
Bool IsOp(U8 char) return (char == '+' || char == '-' || char == '*' || char == '!');
Bool IsBr(U8 char) return (char == '(' || char == ')');
Bool IsSpace(U8 char) return (char == ' ' || char == 5);
Bool IsAlpha(U8 char) return (char >= 65 && char <= 122);
Bool IsLogicOp(U8 *str) return (!StrCmp(str, "or") || !StrCmp(str, "xor") || !StrCmp(str, "xor"));

U8 *ReAlloc(U8 *old, I64 new_size) {

  I64 old_size = sizeof(old) / sizeof(U8);

  if (old_size >= new_size) return old;

  U8 *new = MAlloc(new_size);
  MemCpy(new, old, new_size);

  Free(old);

  return new;

}

Lexer *LexerInit(U8 **content) {

  Lexer *l = MAlloc(sizeof(Lexer));
  l->content = *content;
  l->content_len = StrLen((*content));
  l->cursor = 0;

  return l;

}

Token *LexerNext(Lexer *l) {

  Token *t = MAlloc(sizeof(Token));
  t->type = TOKEN_NULL;
  t->next = NULL;
  t->txt_len = 0;
  t->value = -1;

  t->txt = MAlloc(sizeof(U8) * (t->txt_len + 1));

  if (!l->content_len) {

    "Error:No Input\n";
    GetChar;
    return NULL;

  }

  while (TRUE) {

    while (IsSpace(l->content[l->cursor])) l->cursor++;


    if (l->cursor >= l->content_len) {

      Free(t->txt);
      t->txt = NULL;

      return t;

    }

    if (t->type == TOKEN_NULL) {

      if (IsNum(l->content[l->cursor])) t->type = TOKEN_NUM;
      else if (IsOp(l->content[l->cursor]) || IsAlpha(l->content[l->cursor])) t->type = TOKEN_OP;
      else if (IsBr(l->content[l->cursor])) t->type = TOKEN_BR;
      else t->type = TOKEN_UNKNOWN;

    }

    t->txt[t->txt_len] = l->content[l->cursor];
    t->txt_len++;

    l->cursor++;


    if ((t->type != TOKEN_NUM || !IsNum(l->content[l->cursor])) && (t->type != TOKEN_OP || !IsAlpha(l->content[l->cursor]))) break;  

    t->txt = ReAlloc(t->txt, sizeof(U8) * (t->txt_len + 1));

  }

  t->txt = ReAlloc(t->txt, sizeof(U8) * (t->txt_len + 1));
  t->txt[t->txt_len] = NULL;

  return t;

}

U0 TokenAdd(Token *head, Token *new) {

  if (head->next == NULL) head->next = new;
  else TokenAdd(head->next, new);

}

Token *GetHead(Lexer *l) {

  Token *head = NULL;
  Token *new = NULL;
  
  while (TRUE) {

    new = LexerNext(l);

    if (!new) return new;

    if (new->type == TOKEN_NULL) break;

    if (head == NULL) {

      head = new;
      new = NULL;

    }

    TokenAdd(head, new);    

  }

  return head;

}

U0 TokenFree(Token *head) {

  if (head != NULL) {


    TokenFree(head->next);
    Free(head);

  }

}

Token *Parse(Token *head) {

  Token *curr = head;
  Token *prev = NULL;
  Token *free_list = NULL;
  Token *new_head = NULL;

  while (curr != NULL) {

    if (curr->type == TOKEN_UNKNOWN) {

      "Syntax error: Unknown token: %d\n", curr->txt[0];
      GetChar;
      return NULL;


    }

    if (curr->next->type == TOKEN_NUM && curr->type == TOKEN_NUM) {

      "Syntax error: No operation between numbers\n";
      GetChar;
      return NULL;

    }

    if (curr->next->type == TOKEN_OP && curr->type == TOKEN_OP) {

      "Syntax error: Not enough numbers\n";
      GetChar;
      return NULL;

    }
    
    if (curr->type == TOKEN_NUM) {

      if (curr->value <0) curr->value = Str2I64(curr->txt);
      new_head = curr;

    }
    

    if (curr->type == TOKEN_BR && !StrCmp(curr->txt ,"(")) {

      curr = Parse(curr->next);
      new_head = curr;

    }

    if (curr->type == TOKEN_OP) {

     if (curr->next->type == TOKEN_BR) curr->next = Parse(curr->next->next);

     if (curr->next->value < 0) curr->next->value = Str2I64(curr->next->txt);

     if (!StrCmp(curr->txt, "*")) curr->value = Mul(prev->value, curr->next->value);
     if (!StrCmp(curr->txt, "+")) curr->value = Add(prev->value, curr->next->value);
     if (!StrCmp(curr->txt, "-")) curr->value = Sub(prev->value, curr->next->value);
     if (!StrCmp(curr->txt, "!")) curr->value = Not(Boolean(curr->next->value));
     if (!StrCmp(curr->txt, "or")) curr->value = Or(Boolean(prev->value), Boolean(curr->next->value));
     if (!StrCmp(curr->txt, "xor")) curr->value = XOr(Boolean(prev->value), Boolean(curr->next->value));
     if (!StrCmp(curr->txt, "and")) curr->value = And(Boolean(prev->value), Boolean(curr->next->value));

      curr->type = TOKEN_NUM;

      new_head = curr;

      Token *free_next = curr->next;
      Token *free_prev = prev;

      prev = curr;
      curr = prev->next->next;

      free_next->next = NULL;
      free_prev->next = NULL;


      if (free_list == NULL) {
        free_list = free_next;
      } else TokenAdd(free_list, free_next);

      TokenAdd(free_list, free_prev);


    } else {

     prev = curr;
     curr = prev->next;

    }

    if (curr->type == TOKEN_BR && !StrCmp(curr->txt, ")")) {

      new_head->next = curr->next;
      break;

    }
    
  }

  TokenFree(free_list);

  if (curr->type != TOKEN_BR) new_head->next = NULL;

  return new_head;

}

U0 Compile(U8 *filename=NULL) {

  Lexer *l;
  Token *head;

  U8 *buff;

  if (filename) {

    CFile *f = FOpen(filename, "r");

    FBlkRead(f, buff);
        
    FClose(f);

  } else{

    buff = GetStr;

  }

  l = LexerInit(&buff);

  head = GetHead(l);

  head = Parse(head);

  if (head) "Output: %d\n\n", head->value;

  TokenFree(head);

}