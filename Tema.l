/* Catalin-Alexandru Ripanu, 333CC */

%option noyywrap
%option nodefault
%option stack

/* Variabile utile ce vor fi utilizate in logica parsarii textului */

%{
    int countHash = 0, countSetext = 0, countEq = 0, countDash = 0;
    char* line;
    int countWordList = 0;
    int countWordQuote = 0;
    int level = 0;
%}

/* Expresiile regulate utile in studiul anumitor situatii in parsare */

delim [a-zA-Z \"\(\)\]\-\{\}\,\.\"\;\:\?\!\'\/\[\]]
structure [a-zA-Z0-9 \"\(\)\]\-\{\}\,\.\"\;\:\?\!\'\/\[\]]
line [a-zA-Z0-9 \"\(\)\]\-\{\}\`\']
comma [a-zA-Z0-9 \"\(\)\]\-\{\}\`\'\,]
list [a-zA-Z0-9\"\(\)\]\-\{\}\`\']
chars [\,\.\"\;\:\?\_\'\/\[\]\$\~]
rest [^\.\"\;\:\?\!\*\_\n\#\'\/\$\\\=]
special [\,\.\'\^\"\;\:\?\!\_\/\$\\\=]
parag [\,\.\'\^\"\;\:\?\!]

/* Starile care descriu, in mare, logica intregului program
   Acestea vor fi prezentate in readme */

%s CODE_BL
%s H_RULE
%s EMPHASIS_S
%s EMPHASIS_D
%s EMPHASIS_SPECIAL
%s BLOCKQUOTES
%s BLOCKQUOTES_FINAL
%s IMAGE
%s IMAGE_PROC
%s LINK
%x PARAGRAPH
%s LIST
%s PREP_LIST
%s PREP_LIST_DECISION
%s ELEM_EMPHASIS
%s ELEM_PROC
%s ELEM_LINK
%s ELEM_LINK_PROC
%s LINK_PROC
%s TITLE_ATX
%s TITLE_SETEXT
%s CODE_BL_SPECIAL
%s DECISION
%x CONSUME_HASH
%x CONSUME
%s PARAG_LINE
%s LINK_SPECIAL
%s IMAGE_SPECIAL

%%

        /*Starea care consuma #-urile de la final*/

<CONSUME_HASH>(#)+ {

        BEGIN(INITIAL);
}

        /* Starile care introduc elementele de accentuare in lungul paragrafului */

<PARAGRAPH>{line}*"**"|{line}*"__" {

        printf("%.*s", yyleng - 2, yytext);
        BEGIN(EMPHASIS_D);
}

<PARAGRAPH>{line}*"*"|{line}*"_" {

        printf("%.*s", yyleng - 1, yytext);
        BEGIN(EMPHASIS_S);
}

        /* Daca s-a terminat paragraful */

<PARAGRAPH,CONSUME>("\n"){1}{line}{1} {

        printf(" ");
        yyless(1);
        BEGIN(PARAGRAPH);
}

<PARAGRAPH><<EOF>> {

        printf(":\n");
        return 0;
}

<PARAGRAPH>("\n"){2} {

        printf(":\n");
        BEGIN(INITIAL);
}

<PARAGRAPH>{line}* {

        printf("%s", yytext);
        BEGIN(CONSUME);
}

        /* Starile care introduc link-urile / imaginile in paragraf */

<PARAGRAPH>{line}+("["){1}({line}|("\n"))*("("){line}*{chars}*[^)]+(")") {

        yyless(0);
        BEGIN(LINK);
}

<PARAGRAPH>(","){line}+("["){1}({line}|("\n"))*("("){line}*{chars}*[^)]+(")") {

        printf(",");
        yyless(1);
        BEGIN(LINK);
}

<PARAGRAPH>{line}+("!["){1}({line}|("\n"))*("("){line}*{chars}*[^)]+(")") {

        yyless(0);
        BEGIN(IMAGE);
}

<PARAGRAPH>(","){line}+("!["){1}({line}|("\n"))*("("){line}*{chars}*[^)]+(")") {

        printf(",");
        yyless(1);
        BEGIN(IMAGE);
}

        /* Starea care retine prima propozitie din paragraf pentru "consum" */

<PARAGRAPH>{line}*{rest}{1} {

        printf("%s", yytext);
        BEGIN(CONSUME);
}

        /* Daca paragraful contine un link in prima propozitie */

<INITIAL>{line}+("["){1}{line}*("\n"){0,1}{line}*("("){line}*{chars}*[^)]+(")") {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":");
        yyless(0);
        BEGIN(LINK);
}

        /* Starea care guverneaza un bloc de cod */

<INITIAL>{line}+(":")("\n"){2}(" "){4}("| ") |
<INITIAL>{line}+(":")("\n"){2}(" "){4}("+ ") |
<INITIAL>{line}+(":")("\n"){2}(" "){4}("* ") |
<INITIAL>{line}+(":")("\n"){2}(" "){4}[0-9]{1}(". ") {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%.*s", yyleng - 7, yytext);
        for(int j = 0; j < level; j++) 
        printf(" ");
        BEGIN(CODE_BL_SPECIAL);
}

        /* Starea care se ocupa de procesarea unei liste */

<INITIAL>{line}+(":")("\n"){2}(" ")*("| ") |
<INITIAL>{line}+(":")("\n"){2}(" ")*("+ ") |
<INITIAL>{line}+(":")("\n"){2}(" ")*("* ") |
<INITIAL>{line}+(":")("\n"){2}(" ")*[0-9]{1}(". ") {

        yyless(0);
        BEGIN(PREP_LIST);
}

        /* Daca paragraful contine o imagine in prima propozitie */

<INITIAL>{line}+("!["){1}{line}*("\n"){0,1}{line}*("("){line}*{chars}*[^)]+(")") {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":");
        yyless(0);
        BEGIN(IMAGE);
}

<INITIAL>{chars}{1}.*("\n") {

        BEGIN(INITIAL);
}

        /* Daca paragraful incepe direct cu o imagine */

<INITIAL>("!["){1}{line}*("\n"){0,1}{line}*("("){line}*{chars}*[^)]+(")") {

        yyless(2);
        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":[");
        BEGIN(IMAGE);
}

        /* Starea care se ocupa de linia de separare */

<INITIAL>("\n")*("*")+(" ")*("\n")|("\n")*("-")+(" ")*("\n") {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf("////////////\n");
}

        /* Starea care se ocupa de citate  */

<INITIAL>("> ") {

        for(int j = 0; j < level + 3; j++) 
        printf(" ");
        printf("\"");
        BEGIN(BLOCKQUOTES);
}

        /* Daca paragraful incepe direct cu un link */

<INITIAL>("["){1}{line}*("("){line}*{chars}*[^)]+(")") {

        yyless(1);
        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%s", yytext);
        BEGIN(LINK);
}

        /* Starea care se ocupa de un paragraf normal */

<INITIAL>{line}+{rest}{1}|{comma}+{rest}{1} {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%s", yytext);
        BEGIN(CONSUME);
}

        /* Starea care decide ce elemente din paragraf se pastreaza */

<PARAGRAPH,CONSUME,DECISION>{special}{1} {

        BEGIN(DECISION);
}

        /* Starea care se ocupa de un paragraf fara elemente speciale */

<INITIAL>{line}+("\n") {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%.*s", yyleng - 1, yytext);
        BEGIN(PARAG_LINE);
}

        /* Daca exista elemente de accentuare in paragraf */

<INITIAL>{line}+"**"|{line}+"__" {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%.*s", yyleng - 2, yytext);
        BEGIN(EMPHASIS_D);

}

        /* Daca un paragraf incepe direct cu elemente de accentuare */

<INITIAL>"**"|"__" {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":");
        BEGIN(EMPHASIS_D);
}

        /* Daca un paragraf incepe direct cu elemente de accentuare */

<INITIAL>"*"|"_" {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":");
        BEGIN(EMPHASIS_S);
}

<INITIAL>"*"{line}+("\n"){1}|"_"{line}+("\n"){1} {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":");
        BEGIN(PARAG_LINE);
}

        /* Daca exista elemente de accentuare in paragraf */

<INITIAL>{line}+"*"|{line}+"_" {

        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%.*s", yyleng - 1, yytext);
        BEGIN(EMPHASIS_S);

}

        /* Starea care verifica daca un header cu = sau - este corect */

<INITIAL>{line}+("\n"){1}[\-\=]{1} {

        countSetext += yyleng;
        line = (char*)malloc((yyleng + 1) * sizeof(char));
        if(line == NULL)
            exit(1);
        strcpy(line, yytext);
        BEGIN(TITLE_SETEXT);

}

        /* Starea care numara #-urile pentru o indentare corecta */

<INITIAL>(#)+ {

        countHash += yyleng;
        BEGIN(TITLE_ATX);
}

        /* Starea care elimina #-urile de la sfarsitul atx-urilor */

<TITLE_ATX>[^#\n]+ {

       countHash *=3;
       for(int j = 0; j < countHash; j++) 
       printf(" ");
       printf("+%s\n", yytext);
       level = countHash;
       countHash = 0;
       BEGIN(CONSUME_HASH);
}

        /* Se verifica daca setext-ul cu - este corect */

<TITLE_SETEXT>("\n"){0,1}(\-)+ {

       countDash += yyleng;
       if(countDash + 1 == countSetext - 2)
       { 
            int ind = 6;
            for(int j = 0; j < ind; j++) 
            printf(" ");
            printf("+ %.*s\n", countSetext - 2, line);
            level = ind;
            
       }
        
            countDash = 0;
            countSetext = 0;
            if(line != NULL)
            free(line);
            line = NULL;
            BEGIN(INITIAL);
}

        /* Se verifica daca setext-ul cu = este corect */

<TITLE_SETEXT>("\n"){0,1}(=)+ {

       countEq += yyleng;
       if(countEq + 1 == countSetext - 2)
       { 
            int index = 3;
            for(int j = 0; j < index; j++) 
            printf(" ");
            printf("+ %.*s\n", countSetext - 2, line);
            level = index;
       }
            countEq = 0;
            countSetext = 0;
            if(line != NULL)
            free(line);
            line = NULL;
            BEGIN(INITIAL);
           
}

<TITLE_SETEXT>{line}+{rest}+ {

            for(int j = 0; j < level; j++) 
            printf(" ");
            printf(":%s:\n", line);
            countSetext = 0;
            if(line != NULL)
            free(line);
            line = NULL;
            BEGIN(INITIAL);
           
}

        /* Starea care pregateste procesarea unei liste */

<PREP_LIST>{line}+(":") {

        if(countWordList !=0)
            countWordList = 0;
        for(int j = 0; j < level; j++) 
        printf(" ");
        printf(":%s\n", yytext);
        for(int j = 0; j < level + 3; j++) 
        printf(" ");
        printf("[");
        BEGIN(LIST);
}

        /* Cazul in care 'antetul' listei face parte dintr-un paragraf */

<PREP_LIST_DECISION>{line}+(":") {

        if(countWordList !=0)
            countWordList = 0;
        for(int j = 0; j < level + 3; j++) 
        printf(" ");
        printf("[");
        BEGIN(LIST);
}

        /* Starea care guverneaza citatele */

<BLOCKQUOTES>(">"){0,1}({list}|("#"))+(","){0,1}(" ")|(">"){0,1}({list}|("#"))+(","){0,1}("\n") {

        countWordQuote++;
        if(countWordQuote == 5)
        {
                printf("%.*s\"\n", yyleng - 1, yytext);
                BEGIN(BLOCKQUOTES_FINAL);
        }
           else
                 if(countWordQuote < 5)
                 {
                     printf("%.*s ", yyleng - 1, yytext);
                     BEGIN(BLOCKQUOTES);
                 }
}

        /* Se continua procesarea citatelor */

<BLOCKQUOTES>("\n"){0,1}("> ") {

            BEGIN(BLOCKQUOTES);
}

        /* Daca procesarea se apropie de final */

<BLOCKQUOTES_FINAL>(" "){0,1}(">"){0,1}{structure}*("\n"){1}(">"){1} {

            BEGIN(BLOCKQUOTES_FINAL);
}

        /* Se trece in starea initiala pentru parsarea textului ramas */

<BLOCKQUOTES_FINAL>(">"){0,1}{structure}*("\n"){2} {

            countWordQuote = 0;
            BEGIN(INITIAL);
}

        /* Starea care se ocupa de un bloc de cod ce nu se afla in lista */

<CODE_BL_SPECIAL>(" ")*[0-9]*(". ") |
<CODE_BL_SPECIAL>(" ")*("* ") |
<CODE_BL_SPECIAL>(" ")*("| ") |
<CODE_BL_SPECIAL>(" ")*("+ ") {

            BEGIN(CODE_BL_SPECIAL);
}

        /* Se continua parsarea */

<CODE_BL_SPECIAL>{structure}+("\n"){1} {

             BEGIN(CODE_BL_SPECIAL);
}

        /* S-a finalizat procesul */

<CODE_BL_SPECIAL>("\n") {

             printf("[code]\n");
             BEGIN(INITIAL);
}

        /* Starea care se ocupa de interogarea unei liste */

<LIST>("\n"){2}(" ")*[0-9]*(". ") |
<LIST>("\n"){2}(" ")*("* ") |
<LIST>("\n"){2}(" ")*("| ") |
<LIST>("\n"){2}(" ")*("+ ") {

            BEGIN(LIST);
}

        /* Daca cuvantul ce urmeaza a fi procesat contine un '\n' pe ultima pozitie */

<LIST>{list}+(","){0,1}("\n"){1} {

            countWordList++;
            if(countWordList == 3)
            {
                BEGIN(ELEM_PROC);
            }
              else
                   {
                     BEGIN(LIST);
                   }
            printf("%.*s", yyleng - 1, yytext);
}

        /* Daca cuvantul ce urmeaza a fi procesat contine un semn de 
        punctuatie pe ultima pozitie */

<LIST>{list}+{chars}{0,1} {

            countWordList++;
            if(countWordList == 3)
            {
                BEGIN(ELEM_PROC);
            }
              else
                   {
                      BEGIN(LIST);
                   }
            printf("%.*s", yyleng - 1, yytext);
}

        /* Daca cuvantul ce urmeaza a fi procesat contine un ' ' pe ultima pozitie */

<LIST>{list}+(","){0,1}(" ") {

            countWordList++;
            if(countWordList == 3)
            {
                printf("%.*s", yyleng - 1, yytext);
                BEGIN(ELEM_PROC);
            }
            else
                {
                   printf("%.*s ", yyleng - 1, yytext);
                   BEGIN(LIST);
                }
}

        /* S-a terminat lista de procesat */

<LIST>("\n") {

            countWordList == 0;
            printf("]\n");
            BEGIN(INITIAL);
}

        /* Daca exista un bloc de cod in lista */

<LIST>("\n"){1}(" "){8}{structure}{1} {

            BEGIN(CODE_BL);
}

        /* Se continua procesarea */

<LIST>("\n")*(" ")+{list}{1} {

            yyless(yyleng - 1);
            BEGIN(LIST);
}

<LIST>(" ")*[0-9]*(". ") |
<LIST>(" ")*("* ") |
<LIST>(" ")*("| ") |
<LIST>(" ")*("+ ") {

            countWordList = 0;
            printf("; ");
            BEGIN(LIST);
}

        /* Daca exista mai multe paragrafe in element */

<LIST>{list}+(","){0,1}{rest}{1} {

            printf("%.*s", yyleng, yytext);
            printf("; ");
            BEGIN(ELEM_PROC);
}

        /* Starea care se ocupa de procesarea unui element */

<ELEM_PROC>{structure}*("\n")*(" ")*{delim}*"*" |
<ELEM_PROC>{structure}*("\n")*(" ")*{delim}*"_" {

            BEGIN(ELEM_EMPHASIS);
}

<ELEM_PROC>{structure}*("\n")*(" ")*{delim}*"**" |
<ELEM_PROC>{structure}*("\n")*(" ")*{delim}*"__" {

            BEGIN(ELEM_EMPHASIS);
}

<ELEM_PROC>{line}+("["){1}{line}*("\n"){0,1}{line}*("("){line}*{chars}*[^)]+(")") {

            yyless(2);
            printf(" [");
            BEGIN(ELEM_LINK);
}

        /* Daca exista un bloc de cod in lista */

<ELEM_PROC>{structure}*("\n")*(" "){8}.{1} {

           BEGIN(CODE_BL);
}

<ELEM_PROC>{structure}*("\n")*(" "){4}.{1} {

           BEGIN(ELEM_PROC);
}

<ELEM_PROC>("\n")+(" "){4}("\n").{1} {

           countWordList = 0;
           BEGIN(INITIAL);
}

<ELEM_LINK>{line}+("["){1} {

           BEGIN(ELEM_LINK);
}

        /* Starea care se ocupa de procesarea unui link din lista */

<ELEM_LINK>{line}*"]" {

           printf("@%s", yytext);
           BEGIN(ELEM_LINK_PROC);
}

<ELEM_LINK_PROC>("("){structure}*+(")") {

           BEGIN(ELEM_PROC);
}

        /* Se trece la urmatorul element */

<ELEM_PROC>{delim}*("\n"){0,2}(" ")*("* "){list}{1} |
<ELEM_PROC>{delim}*("\n"){0,2}(" ")*[0-9.]*(" "){list}{1} {

            yyless(yyleng - 1);
            countWordList = 0;
            printf("; ");
            BEGIN(LIST);
}

<ELEM_PROC>{delim}*("\n"){0,2}(" ")*("| "){list}{1} |
<ELEM_PROC>{delim}*("\n"){0,2}(" ")*("+ "){list}{1} {

            yyless(yyleng - 1);
            countWordList = 0;
            printf("; ");
            BEGIN(LIST);
}

        /* S-a terminat lista de procesat */

<ELEM_PROC>((" "){0,3}{list})*("\n"){1,2}{line}{1} {

            yyless(0);
            countWordList = 0;
            printf("]\n");
            BEGIN(INITIAL);
}

<ELEM_PROC>{delim}*("\n"){0,2}(" ")*{list}*("\n") {
        
            countWordList = 0;
            printf("]\n");
            BEGIN(INITIAL);
}

        /* Daca exista elemente de accentuare in lista */
 
<ELEM_EMPHASIS>{line}+"*"|{line}+"_" {

            printf(" <%.*s>", yyleng - 1, yytext);
            BEGIN(ELEM_PROC);
}

        /* Daca exista elemente de accentuare in lista */

<ELEM_EMPHASIS>{line}+"**"|{line}+"__" {

            printf(" <%.*s>", yyleng - 2, yytext);
            BEGIN(ELEM_PROC);
}

        /* Stari care se ocupa de blocul de cod din lista */

<CODE_BL>({structure}|("#")|("*"))*("\n")(" "){0,8} {

            BEGIN(CODE_BL);
}

<CODE_BL>({structure}|("#")|("*"))*("\n")(" "){12} {

            BEGIN(CODE_BL);
}

<CODE_BL>({structure}|("#")|("*"))*("\n"){2}{structure}{1} {

            yyless(yyleng - 1);
            countWordList == 0;
            printf(" [code]");
            BEGIN(ELEM_PROC);
}

<CODE_BL>(" ")*{structure}{1} {

            printf(" [code]");
            BEGIN(ELEM_PROC);
}

        /* Daca s-a terminat de parsat blocul  */

<CODE_BL>{structure}*("\n"){2}(" ")*[0-9]*(". ") |
<CODE_BL>{structure}*("\n"){2}(" ")*("* ") |
<CODE_BL>{structure}*("\n"){2}(" ")*("| ") |
<CODE_BL>{structure}*("\n"){2}(" ")*("+ ") {

            countWordList = 0;
            printf(" [code]; ");
            BEGIN(LIST);
}

        /* Stari care ajuta la procesarea imaginilor */

<IMAGE>{line}+("!["){1} {

            printf("%.*s[", yyleng - 2, yytext);
}

<IMAGE>{line}*("]") {

            printf("!%s", yytext);
            BEGIN(IMAGE_PROC);
}

<IMAGE>{line}*("\n"){1}{line}*"]" {

            yyless(0);
            BEGIN(IMAGE_PROC);
}

        /* Daca mai exista imagini de procesat in paragraf */

<IMAGE_PROC>("("){line}*{chars}*[^)]+(")") {

            BEGIN(PARAGRAPH);
}

<IMAGE_PROC>{line}*("\n") {

            printf("!%.*s ", yyleng - 1, yytext);
            BEGIN(IMAGE_PROC);
}

<IMAGE_PROC>{line}*"]" {

            printf("%s", yytext);
            BEGIN(IMAGE_PROC);
}

<IMAGE>("(").*(")")("\n"){1} {

            printf(":\n");
            BEGIN(INITIAL);
}

<IMAGE>{line}+("\n"){1} {

            printf("%.*s ", yyleng - 1, yytext);
            BEGIN(PARAG_LINE);
}

<IMAGE>{line}+("\n"){1}.{1} {

            yyless(yyleng - 1);
            printf("%.*s ", yyleng - 1, yytext);
            BEGIN(IMAGE);
}

        /* Stari care se ocupa de procesarea listelor din paragrafe */

<LINK>{line}+("["){1} {
        
            printf("%s", yytext);
}

<LINK>{line}*"]" {

            printf("@%s", yytext);
            BEGIN(LINK_PROC);
}

<LINK>{line}*("\n"){1}{line}*"]" {

            yyless(0);
            BEGIN(LINK_PROC);
}

<LINK_PROC>("("){line}*{chars}*[^)]+(")") {

            BEGIN(PARAGRAPH);
}

<LINK_PROC>{line}*("\n") {

            printf("@%.*s ", yyleng - 1, yytext);
            BEGIN(LINK_PROC);
}

<LINK_PROC>{line}*"]" {

            printf("%s", yytext);
            BEGIN(LINK_PROC);
}

<LINK>("(").*(")")("\n"){1} {

            printf(":\n");
            BEGIN(INITIAL);
}

<LINK>{line}+("\n"){1} {

            printf("%.*s ", yyleng - 1, yytext);
            BEGIN(PARAG_LINE);
}

<LINK>{line}+("\n"){1}.{1} {

            yyless(yyleng - 1);
            printf("%.*s ", yyleng - 1, yytext);
            BEGIN(LINK);
}

        /* Stari care reprezinta logica paragrafelor */

<PARAG_LINE>{line}+"*"|{line}+"_" {

            printf(" %.*s", yyleng - 1, yytext);
            BEGIN(EMPHASIS_S);
}

<PARAG_LINE>{line}+"**"|{line}+"__" {

            printf("%.*s", yyleng - 2, yytext);
            BEGIN(EMPHASIS_D);
}

<PARAG_LINE>{line}+("["){1}{line}*("("){line}*{chars}*[^)]+(")") {

             yyless(0);
             BEGIN(LINK);
}

<PARAG_LINE>{line}+("!["){1}{line}*("("){line}*{chars}*[^)]+(")") {

             yyless(0);
             BEGIN(IMAGE);
}

<PARAG_LINE>(" ")*{line}+("\n") {

             printf(" %.*s", yyleng - 1, yytext);
             BEGIN(PARAG_LINE);
}

        /* Finalul paragrafului */

<PARAG_LINE><<EOF>> {

             printf(":\n");
             return 0;
}

<PARAG_LINE>("\n"){1} {
        
             printf(":\n");
             BEGIN(INITIAL);
}

<PARAG_LINE>("#"){1}|("-"){1}|("="){1}|("*"){1}|("_"){1} {

             yyless(0);
             printf(":\n");
             BEGIN(INITIAL);
}

<PARAG_LINE>{list}+{rest}+ {

             printf(" %s", yytext);
             BEGIN(CONSUME);
}

<PARAG_LINE>(" ")*{rest}+ {

             BEGIN(CONSUME);
}

        /* Starea care selecteaza elementele importante
        atunci cand in paragraf exista un semn de punctuatie */

<DECISION>{line}+("[") {

             yyless(yyleng - 1);
             BEGIN(DECISION);
}

<DECISION>{line}+("![") {

              yyless(yyleng - 2);
              BEGIN(DECISION);
}

        /* Verificarea imaginilor si link-urilor */

<DECISION>("["){structure}+("("){line}*{chars}*[^)]+(")") {

               printf(" ");
               yyless(1);
               BEGIN(LINK_SPECIAL);
}

<DECISION>("!["){structure}+("("){line}*{chars}*[^)]+(")") {

                printf(" ");
                yyless(2);
                BEGIN(IMAGE_SPECIAL);
}

<DECISION>("("){line}*{chars}*[^)]+(")") {

                BEGIN(DECISION);
}

        /* Procesarea elementelor de accentuare */

<DECISION>{line}*"*"|{line}*"_" |
<DECISION>{line}*"**"|{line}*"__" {

                 printf(" ");
                 BEGIN(EMPHASIS_SPECIAL);
}
 
<EMPHASIS_SPECIAL>{line}+"**"|{line}+"__" {

                 printf("<%.*s>", yyleng - 2, yytext);
                 BEGIN(DECISION);
}

<EMPHASIS_SPECIAL>{line}+"*"|{line}+"_" {

                 printf("<%.*s>", yyleng - 1, yytext);
                 BEGIN(DECISION);
}

        /* Prelucrarea imaginilor / link-urilor */

<LINK_SPECIAL>{structure}+("]") {

                 printf("[@%s", yytext);
                 BEGIN(DECISION);
}

<IMAGE_SPECIAL>{structure}+("]") {

                 printf("[!%s", yytext);
                 BEGIN(DECISION);
}

<DECISION><<EOF>> {

                  printf(":\n");
                  return 0;
}

<DECISION>{line}*(":")("\n"){2}(" ")*("* ") |
<DECISION>{line}*(":")("\n"){2}(" ")*[0-9]{1}(". ") {

                   printf(":\n");
                   yyless(0);
                   BEGIN(PREP_LIST_DECISION);
}

<DECISION>{line}*(":")("\n"){2}(" ")*("| ") |
<DECISION>{line}*(":")("\n"){2}(" ")*("+ ") {

                    printf(":\n");
                    yyless(0);
                    BEGIN(PREP_LIST_DECISION);
}

        /* Stari care parseaza astfel incat sa se obtina
        cuvinte de interes ce se afla dupa prima propozitie */

<DECISION>{line}*{rest}{1} {

                    BEGIN(CONSUME);
}

<DECISION>{comma}*("\n"){1,2} {

                    printf(":\n");
                    BEGIN(INITIAL);
}

<DECISION>("\n"){chars}{1} {

                     yyless(1);
                     BEGIN(DECISION);
}

<DECISION>("\n"){line}{1} {

                    yyless(1);
                    BEGIN(DECISION);
}

<DECISION>(","){0,1}{line}*("\n"){line}{1} {
        
                    yyless(yyleng - 1);
                    BEGIN(DECISION);
}

<DECISION,CONSUME>("\n") {

                     printf(":\n");
                     BEGIN(INITIAL);
}

        /* Prelucrarea elementelor din paragrafe obisnuite */

<EMPHASIS_D>{line}+"**"|{line}+"__" {

                      printf("<%.*s>", yyleng - 2, yytext);
                      BEGIN(PARAGRAPH);
}

<EMPHASIS_S>{line}+"*"|{line}+"_" {

                      printf("<%.*s>", yyleng - 1, yytext);
                      BEGIN(PARAGRAPH);
}

<H_RULE>"\n" {

}

<*>.|\n {
            if(line != NULL)
            {
                free(line);
                line = NULL;
            }
            countSetext = 0;
            BEGIN(INITIAL);
}

%%

int main(int argc, char** argv)
{
    FILE *fp;
    char* filename = (char*)malloc(10*sizeof(char));

    if(filename == NULL)
       {
          exit(1);
       }

    if(argv[1] == NULL)
        {
           printf("Type a file as an argument!\n");
           exit(1);
        }

    strcpy(filename, argv[1]);
    fp = fopen(filename,"r");
    yyin = fp; 
    yylex();
    free(filename);
    free(yytext);
    return 0;
}