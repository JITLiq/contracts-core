## post deployment flow

-   syncOperators(); [`0xAAFb9A06bA0818BeB046069433206C67c9b3F639`,`0x82254e340F58c2EEE67845C5D63f7192443CB401`]
-   transfer usdc to SM
-   set peers on dest & src entrypoints
-   approve initiator to entrypoint on src
-   approve LP to entrypoint on desc
-   set dest entrypoint on source AR
-   sync on dest SM
