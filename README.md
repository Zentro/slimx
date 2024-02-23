
# SlimX
Basically Signal but built by 3 amateur people in (mostly) 24 hours.

## What is it really?
A CodeRED Hackathon project implementing the PQXDH protocol in a real-time chat app. The protocol is 
just fancy handshake to exchange a secret key securely (though it still lacks plenty of stuff 
to actually be secure in the real world, namely an SSL connection between client and server). 

## Some specific details about current implementation...
Messages are only locally decrypted at the client side. Server merely acts as a coordinator. 
Messages are encrypted with AES-256 (though without an associated data so far). 
The PQKEM used is the Kyber library from Argyle-Software. 

## What's the next big thing for it? (updated from time to time)
The Double Ratchet Algorithm!!! There is currently no forward secrecy so any compromise 
of the shared key immediately means that the conversation will be entirely visible, which 
is NOT good :(

## How to run/build
For the server:

> The /server folder has a .env file specifying the MySQL database so   
> that needs to be changed to  whatever the local server needs.
> 
> Diesel can be installed through 'cargo install diesel' (which is much  
> easier on Linux).
> 
> Run 'diesel migration run' in the /server folder to setup the database.
> Anytime you want to just drop the database, just do 'diesel migration redo -n 7'
> 
> Then, 'cargo run' will start up the server.

For the client:

> Install Flutter and flutter_rust_bridge (https://github.com/fzyzcjy/flutter_rust_bridge)
>  
> Run 'flutter_rust_bridge_codegen generate' just in case.
>   
> Run 'flutter run' to start the client.
>
> You'll have to resize the client for it to switch to mobile mode. Currently, the
> desktop/tablet screen is used as a debug button to also wipe all stored data.
