# WetRockPolice ![](/docs/police-logo.png)

![Tests](https://github.com/Syntaf/wetrockpolice/workflows/Test/badge.svg)
[![codecov](https://codecov.io/gh/Syntaf/wetrockpolice/branch/master/graph/badge.svg)](https://codecov.io/gh/Syntaf/wetrockpolice)

## Table of Contents

- [Overview](#Overview)
  - [Running Locally with Docker](#Running-Locally-with-Docker)
- [Contributing](#Contributing-Guide)
  - [Coding Standards](#Coding-Standards)
- [Development Guide](#Development-Guide)
  - [Model Overview](#Creating-a-New-Watched-Area-Site-Section)
  - [Frontend Assets](#Models-Overview)
  - [Creating or Updating Landing Page Images](#Creating-or-Updating-Hero-Images)
# Overview

WetRockPolice is an open source project written in Rails 6 + PostgreSQL and hosted on Kubernetes. The project has three key goals:
- Spread awareness about the ethics of climbing on wet rock at an at-risk area.
- Display historical rain information to help climbers make informed decisions
- Enable organizations to connect with visiting climbers

Contibutors are welcome! Please visit the [issues](https://github.com/Syntaf/wetrockpolice/issues) tab for ideas on how to contribute.

## Running Locally with Docker

1. Clone the repository
    ```
    ~$: git clone git@github.com:Syntaf/wetrockpolice.git
    ```

2. Copy over the example environment and fill in any optional integrations
   ```
   ~$: cd wetrockpolice
   ~$: cp .env.example .env
   ~$: vim .env
   ```

3. Build the containers, and bring them up once finished
    ```
    ~$ cd wetrockpolice
    ~$ docker-compose build && docker-compose up -d
    ```

4. Run the containers (omit -d if you'd like them to run attached to your shell)
   ```
   ~$ docker-compose up -d
   ```

6. Run pending migrations
    ```
    ~$ docker-compose exec web rails db:migrate
    ~$ docker-compose exec web rails db:migrate RAILS_ENV=test
    ```

7. Seed development data
    ```
    ~$ docker-compose exec web rails db:seed
    ```

8. Visit https://localhost:3001


# Contributing

This repository uses [Github Actions](https://github.com/features/actions) for continuous integration. Before a pull request can be merged into master it must pass all existing / new tests *as well* as linting (Rubocop). It is **highly** recommended that you use Rubcop during development as to not have to go back and forth between CI results and your code.

#### Using Rubocop on Visual Studio Code:

- Download the [Solargraph Extension](https://github.com/castwide/vscode-solargraph) and use these settings:

  ```
    // settings.json

    {
        "solargraph.diagnostics": true,
        "solargraph.formatting": true
    }

  ```

  **Note: If your solargraph server ever crashes and VSCode stops linting your work, use the developer window reload command to restart it.

#### Using Rubocop from the command line

If you're opposed to VSCode or prefer using a different editor, you can always run rubocop from the command line inside the project:

```
~$: cd wetrockpolice
~$: rubocop
```

By default the configuration files should be detected and used, so no arguments are needed.

## Coding Standards

For a full manifesto on coding standards, Rubocop will adhere mostly to the [Ruby Style Guide](https://rubystyle.guide/). In short, keep these key things in mind:

- Keep lines under **80** characters
- Use standard `snake_case` for varible and method naming
- Use `do end` instead of `{ }` when writing multi-line blocks
- Keep the length of blocks under **25** lines.
- Don't put business logic inside controllers. Skinny controllers, fat models

While WRP only supports Red Rock currently, the backend is designed to support multiple areas in the future and that should be kept in mind during development. Make sure any changes made consider a future where there are many active areas that can display precipitation data.


# Development Guide

## Models Overview

The database is designed to support a site that one day may have many watched areas (Red Rock, Moe's Valley, Etc). Below is an Entity Relationship Diagram that can be used to gain an understanding of the models defined in this project.

![ERB via LucidChards](/docs/WetRockPolice_ERD.png)

#### LocalClimbingOrg

A not-for-profit climbing coalition managing one or more watched areas. The **slug** field is used for displaying the coalitions membership signup form within the watched area, i.e. `/redrock/sncc` where `sncc` is the slug of the climbing org instance.

#### WatchedArea

Represents an area being monitored for rain. Uses it's `slug` field to define a unique "microsite" within WRP consisting of a:
- Landing page (`/redrock`)
- Rainy day options page (`/redrock/rainy-day-options`)
- FAQ page (`/redrock/faq`)
- Membership signup page (`/redrock/sncc`)

Fields like `info_bubble_excerpt` and `park_type_word` allow for dynamic content on the landing page depending on the current watched area being rendered.

#### RainyDayArea

Links a climbing area to a watched area. Does not contain any information itself, just serves to define relationships between climbing areas and a watched area.

#### ClimbingArea

A climbing crag / area. Does not contain any associations to a watched area so that the same climbing area can be a "rainy day option" for multiple watched areas if needed.

#### Location

Contains a pair of coodinates in the EPSG:3857 WGS 84 / Pseudo-Mercator system, and an optional zoom attribute.

#### User

A standard devise-based user model. The one unique thing worth mentioning is the _manages_ attribute, which contains an array of watched area IDs. I.e. `user.manages == [1]` means the user can manage all db data relating to Red Rock.

## Frontend Structure

The asset pipeline is kept very simple intentionally. All assets are compressed, loaded and cached on a users first page visit, meaning there are no *page specific* JS/SCSS files.

JS code is encapsulated into vanilla "controllers"; each controller is responsible for managing the functionality on a given type of page. Since all of these controllers are loaded globally, you can immeditely use them at the bottom of your view template:

```erb
<!-- area/rainy_day_options/index.html.erb -->

<div class="rainy-day-content">
  <!-- ... -->
</div>
<script>
    // All controllers are loaded and in global scope
    var pageController = new RainyDayController({ /* ... */ });
</script>
```

## Creating or Updating Hero Images

This repository uses a custom strategy for loading large background images on the client to ensure the first-load experience isn't poor. Without this strategy, the page would load with the large image missing, then slowly load the image top-down as if the page was being printed out.

On page load, the browser will first load and display an extremely small version of the image (20x20 pixels for example) and apply a large gussian blur to distort the pixel borders. In the background, javascript is used to fetch the fully sized background image; once finished the full image will be swapped for the blurred image with a fade-in transition. The end result is a page load that looks like the background image is just being animated into view rather than slowly loaded.

Because of this strategy however, updating landing page images can be a little more involved. Follow these steps for creating or updating hero images:

1. Create two copies of your desired hero image: One which is the original (high quality) image and another which has had it's size dramatically scaled down (less then 50x50 pixels). Ensure you've maintained the aspect ratio when scaling the image down.

2. Move your two copies into `app/assets/images/watched-area-slug`, calling the original image `hero-image.jpg` and the small image `hero-image-small.jpg`.

3. Go to https://www.base64-image.de/ and load your small image to receive a base64 encoded string. Copy that string to your clipboard and open `application.html.erb`. In the custom style block at the head, add two new SCSS rules:
    ```css
      /* Watched Area */
      .hero-header.<slug> {
        background: url("data:image/jpeg;base64,/9j/4AAQSkZJ...");
        background-repeat: no-repeat;
        background-position: center center;
        background-size: cover;
      }
      .hero-header.<slug>.hero-header-loaded {
        background-image: url(<%= asset_path 'watchedarea/hero-image.jpg' %>);
      }
    ```

    Where `<slug>` refers to the slug of the watched area, e.g. `redrock` or `castlerock`.
    Since the initial background is a base64 encoded image, the page will almost always load with it already painted (albeit heavily blurred). The second rule will swap the background image while the image has been successfully loaded in the background (avoiding the top-down loading view).

4. Load the page and ensure your page transitions from the small image to large image. If you're having trouble determing if the small image is loading properly you can comment out `imageLoader.load()` in `views/area/watched_area/index.html.erb`, this will cause the page to load with only the small image
