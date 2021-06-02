package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	"github.com/rs/zerolog/hlog"
	"github.com/rs/zerolog/log"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		log.Warn().Msg("PORT is undefined, assuming 80")
		port = "80"
	}

	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Get("/*", handler)
	fmt.Println("Listening to port", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal().Err(err).Msg("ListenAndServe")
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	hlog.FromRequest(r).Info().
		Str("method", r.Method).
		Stringer("url", r.URL).
		Msg("")
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
	if r.URL.RawQuery == "debug" {
		fmt.Fprintf(w, "\n\n\n-- env:\n\n")
		for _, e := range os.Environ() {
			fmt.Fprintf(w, "%s\n", e)
		}
		fmt.Fprintf(w, "\n\n-- headers:\n\n")
		for k, v := range r.Header {
			fmt.Fprintf(w, "%s: %s\n", k, strings.Join(v, ","))
		}
	}
}