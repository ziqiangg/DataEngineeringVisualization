// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "24",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "Libertinus Serif", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Libertinus Serif", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Libertinus Serif", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => context {
    // Find out the final number of the heading counter.
    let levels = counter(heading).get()
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  }

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + departments),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  set par(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
#import "@preview/fontawesome:0.5.0": *

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Visualisation of Singapore's Fertility Crisis], 
  // TODO: use Quarto's normalized metadata.
   authors: [Akram, M., Guo, Z., Tan, G., Cheong, W. and Chew, T.], 
   departments: [~], 
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/sit.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [AAI1001 AY24/25 Tri 2 Team Project], 

  // Any URL, like a link to the conference website.
   footer_url: [~], 

  // Emails of the authors.
   footer_email_ids: [Team 07], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
   keywords: ("AAA", "BBB", "CCC"), 

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

= Introduction
<introduction>
Singapore faces a demographic crisis with one of the world's lowest fertility rates. Understanding the underlying socioeconomic factors is crucial for policy formulation and national planning. This project analyses #strong[three decades of fertility and labour force data] to identify patterns and relationships that visualisations from the source neglects. Using various packages in R, we will create a poster that thoughtfully displays the socioeconomic factors that influence fertility/birth rates in Singapore by using fertility rate data sourced from different websites.

#block[
#callout(
body: 
[
Understanding the underlying #strong[socioeconomic factors] is crucial for policy formulation and national demographic sustainability.

]
, 
title: 
[
Research Focus
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
= Original Visualisation
<original-visualisation>
#figure([
#box(image("images/total_fertility_rate.png"))
], caption: figure.caption(
position: bottom, 
[
Total fertility rate from 2019 to 2023
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-1>


= Original Visualisation Analysis
<original-visualisation-analysis>
+ #strong[No data validation];: There is no data validation provided in the graph.

+ #strong[Limited range];: The graph only displays data from 2019-2023. This is not a wide enough of a range to make conclusive statements.

+ #strong[Missing socioeconomic factors];: There are no socioeconomic factors listed to support the decline in the fertility rate. They are crucial information that can reinforce the nature of the graph.

+ #strong[Static visualisation];: The original visualisation lacks depth and interactive features that would otherwise allow the user to better understand the graphs. The static natures does not allow the user to hover or click on data points to gain more information.

= Suggested Improvements
<suggested-improvements>
+ #strong[Inlcude data validation];: Add comprehensive data validation along with outlier analysis. This aims to ensure the accuracy and reliability of the data presented.

+ #strong[Extended analysis];: Increase the range of the data to 1990-2022. This will provide a more comprehensive view of the fertility trends in Singapore which allows for better analysis and understanding of long-term patterns.

+ #strong[Integrate socioeconomic factors];: Integrate socioeconomic factors such as labour force participation and marital status. This will provide a more holistic view of the factors influencing fertility rates. This allows for better policy formulation and understanding of the demographic trends.

+ #strong[Dynamic visualisation];: Ensure that the visualisation consists of a fully interactive dashboard. This will allow users to interact with the data, such as hovering over data points to see more information. They can also filter by different socioeconomic factors and viewing age-specific fertility rates. This enhances user engagement and understanding of the data.

= Implementation
<implementation>
#block[
#set enum(numbering: "i.", start: 1)
+ Data Sources
]

#table(
  columns: (19.85%, 9.56%, 13.24%, 38.97%, 18.38%),
  align: (auto,auto,auto,auto,auto,),
  table.header([Dataset], [Source], [Time Period], [Variables], [Records],),
  table.hline(),
  [Fertility Rates], [SingStat], [1960-2024], [Age-specific fertility rates, Total fertility rate], [17 variables wide format],
  [Labour Force (Working)], [data.gov.sg], [1991-2022], [Female labour force by age & marital status], [5 columns long format],
  [Labour Force (Not working)], [data.gov.sg], [1991-2022], [Females outside labour force by age & marital status], [5 columns long format],
)
#block[
#set enum(numbering: "i.", start: 2)
+ Software
]

- `crosstalk` -- Enables interactivity between HTML widgets
- `tidyverse` -- Loads core tidy data science packages like `ggplot2`, `dplyr` and `tidyr`
- `viridis` -- Provides colourblind-friendly color palettes for plots
- `ggpp` -- Adds plot annotations like equations and labels in `ggplot2`
- `ggrepel` -- Prevents overlapping text labels in `ggplot2` plots
- `RColorBrewer` -- Offers pre-made color palettes for maps and plots
- `htmltools` -- Tools for creating and customizing HTML content in R
- `dplyr` -- Grammar of data manipulation
- `knitr` -- For dynamic report generation
- `tools` -- Base R utilities for package and file management
- `ggiraph` -- Adds tooltips and interactivity to `ggplot2` plots
- `ggplot2` -- Core package for creating elegant plots
- `plotly` -- Converts static plots to interactive plots
- `janitor` -- Cleans messy data
- `gt` -- Creates beautiful tables for reporting
- `stringr` -- Simplifies string operations
- `scales` -- Formatting scales and labels in visualisations
- `forcats` -- Handles categorical variables more easily
- `DT` -- R interface to interactive DataTables (tables with filters/sorting).
- `glue` -- Embeds R expressions in strings using `{}`

#block[
#set enum(numbering: "i.", start: 2)
+ Workflow
]

#block[
#set enum(numbering: "1)", start: 1)
+ Exploratory Data Analysis:

+ Feature Engineering:
]

== Data Cleaning and Reshaping Workflow
<data-cleaning-and-reshaping-workflow>
- Handle all missing values by converting `"na"` and `"-"` strings to `NA`.

- Standardise age bands by renaming columns to consistent labels like `"15-19"` and align across datasets.

- Filter data by keeping only years from #strong[1990 to 2022] to match across fertility and labour datasets.

- Pivot fertility data from wide to long format for year-wise plotting.

- Rename `age` to `age_band`, clean column names using consistent formatting.

- Introduce `uom` (unit of measurement) column to specify rate scaling.

- Divide labour force counts by 1,000 to match y-axis scale.

- Keep age-specific fertility rates and Total Fertility Rate (TFR).

- Add `"All"` age group to show total counts by year and marital status for plots and filters.

- Use the same cleaning logic for `fertility`, `not_working`, and `work` tibbles for consistency.

- Check for missing data and outliers.

- Join the datasets to create a single tibble with all the necessary information for analysis.

#block[
#set enum(numbering: "1)", start: 3)
+ Data Visualisation:
]

- Define Colors: Create a color palette representing the socioeconomic factors influencing fertility rates such as labour force participation and marital status.
- Graph Properties: Configure interactivity by allowing user to click and zoom on the data points.
- Layout: Set the title and overall layout properties for an informative and visually appealinggraph.

= Improved Visualisation
<improved-visualisation>
#figure([
#box(image("images/total_fertility_rate.png"))
], caption: figure.caption(
position: bottom, 
[
Total fertility rate from 2019 to 2023
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-1>


Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim

:::

= Insight
<insight>
= Further Suggestions for Interactivity
<further-suggestions-for-interactivity>
= Conclusion
<conclusion>
= References
<references>




