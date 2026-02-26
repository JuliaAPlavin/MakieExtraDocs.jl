### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ 4a8ce771-7416-4ec1-a342-4820ae4ced7a
using AccessorsExtra

# ╔═╡ 62995210-516f-4564-a095-76d3ef966e09
using MakieExtra; import GLMakie

# ╔═╡ 2cac5727-8bd9-4382-8b76-5e8a18e5ea70
using StructArrays

# ╔═╡ e7b7cbab-8095-4ea0-ac8b-d361bfe40d63
using Unitful

# ╔═╡ 18035dd8-736a-4ac5-8562-2cbf16b6298b
using IntervalSets

# ╔═╡ 1f789967-0357-4b61-a9af-1f72f2a28c5c
using DataManipulation

# ╔═╡ e559ff6a-b3fc-4067-8597-0e7488b53d7f
using PyFormattedStrings

# ╔═╡ c756d828-7f29-4bab-9c39-0dee70116c88
using DateFormats

# ╔═╡ 8efce9ac-d93d-4b8f-87e2-b775522da819
using PlutoUI

# ╔═╡ d6de5f88-0b1e-4f7c-b87a-f27839c0cc9b
using VLBIFiles, VLBIPlots

# ╔═╡ a4c423f8-07d4-4658-b684-3324086d15dd
md"""
# `FPlot`: composable plotting specification
"""

# ╔═╡ 1ad2f738-9ef3-4677-9f92-72cc0f670dc9
md"""
!!! note
	What started as a simple proof of concept in the #makie channel, became the primary way I do plotting in `Makie`. \
	The chapters below outline the motivation for `FPlot`, and provide examples to illustrate its usage and the main features.
"""

# ╔═╡ 493fa6c3-68b4-47f7-8c09-d1857d4fede0
md"""
## Philosophy and design
"""

# ╔═╡ d092ff18-93aa-4c81-8af7-62613e074f51
md"""
Most plotting libraries, including Makie, tend to take different properties of the plot (xy coordinates, color, size, ...) as separate arrays.\
This is convenient for tiny self-contained snippets, hard to argue with the simplicity:
"""

# ╔═╡ 4c171005-d3e5-4678-b454-901ccc824c1e
scatter(rand(100), rand(100))

# ╔═╡ 51648500-f070-4dff-9b3f-a82d40335860
md"""
However, this approach can be suboptimal for anything even slightly more involved.\
**It's very common that one has a dataset – a collection of elements – and thinks of plotting in terms of these elements.** Like, "for `r ∈ data`, plot `abs(r.value)` along the x axis, `angle(r.value)` along the y axis, and color them by `r.age`.

Makie itself partially supports this way of passing plotting arguments. It can take spatial coordinates as a single array: a Vector of Points.\
Still, other attributes like color need to be passed separately. And even when only coordiates are involved (no other plotting attributes), it can be useful to know more about the underlying dataset than raw Points can provide. See feature highlights below for neat examples :)

**`FPlot` is an object that encapsulates the whole plot definition.** Let's see how it works.
"""

# ╔═╡ 5bf41e25-0992-4186-84af-00d4cf3e5c6e
# that's our dataset
# vector of namedtuples for simplicity, but any collection of any objects would work
data = [
	(value=i + (i+rand())*im, age=i^2)
	for i in 1:100
]

# ╔═╡ 7c0c7bd7-2842-47c0-8240-8beefc37de26
# create the FPlot object
fplt = FPlot(
	data,  # the first argument is the dataset
	# further positional and keyword arguments directly correspond to Makie arguments
	# they are mapped over the dataset and forwarded to Makie
	r->abs(r.value), r->angle(r.value);  # what to plot on x and y axes 
	color=r->r.age,  # element-dependent keyword arguments
	colormap=Ref(:turbo)  # Ref() to specify scalar attributes forwarded to Makie and not mapped over data
)

# ╔═╡ e9c1096f-af1b-4005-9817-214ae7e8a5a9
scatter(fplt, markersize=15)  # specify more constant plot arguments here if needed

# ╔═╡ c1917d5f-791f-4c81-8bcf-63e8b6d7a83e
md"""
This paradigm is very widely applicable, to lots of plot types and scenarios. Try to play with it and feel for yourself!

*Note: exact details of `FPlot` behavior are considered experimental and subject to change, as well as functions/arguments naming. The concept itself is expected to remain though.*
"""

# ╔═╡ d9489617-3001-47e4-94af-cdbfdb96d7d6
md"""
## Feature highlights
"""

# ╔═╡ fe7ebf74-4dcc-4de4-95fc-bbd1367c01a0
md"""
### Automatic axis labels
"""

# ╔═╡ 37e474a3-30ac-4ada-9ddd-8fb521b76133
md"""
`FPlot` objects know what they are plotting on each axis, making it possible to generate nice labels automatically. The actual label generation is done by `Accessors`/`AccessorsExtra`, so please use the `@o ...` syntax instead of anonymous functions to utilize it.

Due to current Makie limitations, setting axis attributes with regular recipes is not possible.\
Wrap the plotting function in `axplot(...)` to get automatic axis labels with `FPlot`, for example `axplot(scatter)` instead of `scatter`:
"""

# ╔═╡ 77f5b4ca-1696-4f6b-8a0c-3fda885867cb
let
	data = StructArray(a=(1:100), b=(1:100).^2)
	fplt = FPlot(data, (@o _.a), (@o _.b))
	axplot(lines)(fplt)
end

# ╔═╡ 80bf77ae-a576-45e7-9796-c993c0a87118
md"""
One can use quite involved functions and still get automatic labeling, thanks to `AccessorsExtra`:
"""

# ╔═╡ 0faeb906-bbf4-4304-9a52-7e15cfa72252
let
	data = StructArray(a=(1:100)u"m", b=(1:100).^2)
	fplt = FPlot(data, (@o ustrip(u"km^3", (_.a*30)^3)), (@o _.b))
	axplot(lines)(fplt)
end

# ╔═╡ 975aec3e-04aa-471f-8883-dce736b2f78b
md"""
### Reusing `FPlot` specification
"""

# ╔═╡ a930e58f-8b02-4100-8bac-4bdbcad5aabd
md"""
Often one wants to show the same data with on several related plots, like a 2d scatter + 1d histograms. `FPlot` is a great fit in these cases:
"""

# ╔═╡ d93d0fa9-e5cd-4410-bee2-755cd710b3f2
let
	data = StructArray(a=randn(1000), b=rand(Int8, 1000))
	fplt = FPlot(data, (@o _.a), (@o _.b))

	fig = Figure()
	scatter(fig[1,1], fplt)
	hist(fig[0,1], fplt)
	hist(fig[1,2], fplt, direction=:x)
	
	colsize!(fig.layout, 2, Relative(0.2))
	rowsize!(fig.layout, 0, Relative(0.2))

	fig
end

# ╔═╡ b0d7d774-e07d-4c3c-b2b6-a016710b09a0
md"""
Of course, `FPlot` just works with other `MakieExtra` tools. In particualr, `multiplot` can often form neat synergies:
"""

# ╔═╡ aebbac13-8f41-41a7-b0d9-ec8b6feef124
let
	data = StructArray(a=randn(1000), b=rand(Int8, 1000))
	fplt = FPlot(data, (@o _.a), (@o _.b))
	fig = Figure()
	axplot(scatter)(fig[1,1], fplt)
	multiplot(fig[0,1], (Hist, VLines => (ymin=0, ymax=0.06, linewidth=0.5)), fplt)
	multiplot(fig[1,2], (Hist, HLines => (xmin=0, xmax=0.06, linewidth=0.5)), fplt, direction=:x)
	colsize!(fig.layout, 2, Relative(0.2))
	rowsize!(fig.layout, 0, Relative(0.2))
	fig
end

# ╔═╡ 06c4630a-32f4-47e2-8484-d0208d93bc17
md"""
### Modifying parts of `FPlot`
"""

# ╔═╡ 2c72a873-c690-46aa-a0db-bf9be62d305a
md"""
`FPlot` objects can be manipulated in a natural way to obtain several plots with the same data and/or the same transformations with some changes from one to another.\
Here's what one should know about `FPlot` objects structure:
- the dataset is available as `fplt.data`
- positional arguments are available with indexing `fplt[1]`, `fplt[2]`, ...; for example, `FPlot(data, (@o _.a))[1] == @o _.a`
- keyword arguments are available as properties; for example, `FPlot(data, color=(@o _.a)).color == @o _.a`
All these parts can be modified with the familiar `Accessors` interface.
"""

# ╔═╡ 68a418ac-b352-4594-99ad-17328f510665
with_theme(Axis=(;width=300)) do
	data = StructArray(a=(1:100), b=(1:100).^2)
	fplt = FPlot(data, (@o _.a), (@o _.b))

	fig = Figure()
	
	axplot(scatter)(fig[1,1], fplt)
	# change/add some data transformations:
	axplot(lines)(fig[1,2], linewidth=5, @insert fplt.color = @o _.a)
	axplot(lines)(fig[1,3], (@set fplt[2] = @o 1/_.b), axis=(;yscale=log10))

	# replace the dataset:
	axplot(scatter)(fig[2,1], (@set fplt.data.b = 1:100))

	resize_to_layout!(fig)
	fig
end

# ╔═╡ e495b551-45e9-41da-9d05-3fbd73aa7f34
md"""
### Dynamic plots: updating `FPlot`
"""

# ╔═╡ 137c903b-d829-47d8-b793-fd4e053844d5
md"""
Keeping the full specification of the plot, both the underlying data and its transformations, makes it straightforward to create dynamic plots. \
In contrast to regular Makie plotting, all components (x, y, color, ...) are updated simultaneously, avoiding potential errors caused by temporary length mismatches.
"""

# ╔═╡ 1cfb255f-9fcc-426f-bc57-bde22eedbf6c
let
	n = Observable(10)
	data = @lift StructArray(a=range(0,step=0.01,length=$n), b=range(0,step=0.01,length=$n).^3)
	fplt = @lift FPlot($data, (@o _.a + 1), (@o _.b), color=(@o _.b))
	axplot(lines, autolimits_refresh=true)(fplt, linewidth=10, colormap=:turbo)
	Record(n, 2:100)
end

# ╔═╡ 46310a44-37fc-4193-b089-8049071b3331
md"""
### Interactivity: data cursor
"""

# ╔═╡ 70bbaf38-f1d9-4373-8b2c-fdc3f49bedd7
md"""
There are several small widgets that can be used together with `FPlot`. \
One is the `DataCursor`: it highlights the axis values when moving the mouse, both in the current Axis and others that share the same dataset and one of the axis coordinates.

This is how `DataCursor` is enabled:
"""

# ╔═╡ a3c56aa3-fb46-4f10-a7df-e96ebeee523e
LocalResource("datacursor.mp4", "autoplay" => "true", "loop" => "true")

# ╔═╡ cf092210-32b6-4ea8-9c16-6ea3104d3d77
let
	n = 100
	data = StructArray(a=range(0,step=0.01,length=n), b=range(0,step=0.01,length=n).^3)

	# create the DataCursor and specify its appearance
	dc = DataCursor(lines=(;color=:black, linestyle=:dash))
	fplt = FPlot(data, (@o _.a), (@o _.b); color=(@o _.b), linewidth=Ref(10), colormap=Ref(:turbo))

	fig = Figure()
	# pass widgets to all plots where they are needed
	axplot(lines, widgets=[dc])(fig[1,1], fplt)
	axplot(lines, widgets=[dc])(fig[1,2], (@set fplt[1] = @o 1/_.a))
	axplot(lines, widgets=[dc])(fig[2,1], (@set fplt[2] = @o 1/_.b))

	fig
end;

# ╔═╡ 2636263c-bc75-48e1-905c-fad4d151edc0
md"""
When using GLMakie or other interactive backends, hold `c` and move your mouse around the figure to activate the data cursor.
"""

# ╔═╡ 038630ce-f172-459d-b953-3222c9017c8b
md"""
### Interactivity: rectangle selector
"""

# ╔═╡ 73b2f789-22ad-40d1-a360-d2e294908276
md"""
A somewhat more involved widget is a `RectSelection`: select a rectangular area in a plot using the mouse, highlight and process elements that fall into that area.

The most basic usage looks like this (again, a pre-recorded animation is shown):
"""

# ╔═╡ 72c35d8e-516d-4925-b250-2e8a496b9540
LocalResource("rectsel1.mp4", "autoplay" => "true", "loop" => "true")

# ╔═╡ 13a47f17-ca59-42c0-8221-97a376c7647a
let
	n = 100
	data = StructArray(a=range(0,step=0.01,length=n), b=range(0,step=0.01,length=n).^3)

	# create the RectSelection and specify its appearance
	rs = RectSelection(poly=(;color=:orange, alpha=0.3))
	fplt = FPlot(data, (@o _.a), (@o _.b); color=(@o _.b), linewidth=Ref(10), colormap=Ref(:turbo))

	fig = Figure()
	# pass widgets to all plots where they are needed
	axplot(lines, widgets=[rs])(fig[1,1], fplt)
	axplot(lines, widgets=[rs])(fig[1,2], (@set fplt[1] = @o 1/_.a))
	axplot(lines, widgets=[rs])(fig[2,1], (@set fplt[2] = @o 1/_.b))

	fig #|> display
end;

# ╔═╡ 225b5175-bda1-40b2-ae90-7f8a3a83a27f
md"""
Ok, it highlights the selected area across axes... But how do we actually utilize the selection and process elements that fall into it?

`mark_selected_data(data, rectsel)` returns a "marked" dataset: one can apply `is_selected(_)` to its elements to check whether they are within the target area. Here, we use it to color the points differently:
"""

# ╔═╡ 8b79b5e9-61bd-40d5-9d78-118e8cbf7b0d
LocalResource("rectsel2.mp4", "autoplay" => "true", "loop" => "true")

# ╔═╡ 0c3da8d7-3632-4020-b565-5ef589b56359
let
	n = 100
	data = StructArray(a=collect(range(0,step=0.01,length=n)), b=collect(range(0,step=0.01,length=n).^3))

	# create the RectSelection and specify its appearance
	rs = RectSelection(poly=(;color=:orange, alpha=0.3))
	marked_data = mark_selected_data(data, rs)
	
	fplt = @lift FPlot($marked_data, (@o _.a), (@o _.b), color=(@o is_selected(_) ? _.b : 0.), markersize=(@o is_selected(_) ? 15 : 5))

	fig = Figure()
	# pass widgets to all plots where they are needed
	axplot(scatter, widgets=[rs])(fig[1,1], fplt, colormap=:turbo)
	axplot(scatter, widgets=[rs])(fig[1,2], (@lift @set $fplt[1] = @o 1/_.a), colormap=:turbo)
	axplot(scatter, widgets=[rs])(fig[2,1], (@lift @set $fplt[2] = @o 1/_.b), colormap=:turbo)

	fig #|> display
end;

# ╔═╡ addc827a-9cc2-4f8d-b0b8-4c5cc594db53
md"""
Another useful function is `selected_data(data, rectsel)`: it returns the subset that only contains selected elements. Let's show their summary statistics:
"""

# ╔═╡ 800091fe-f1ec-4069-bbea-dbcb2420f56f
LocalResource("rectsel3.mp4", "autoplay" => "true", "loop" => "true")

# ╔═╡ a2c1e9b6-bd46-4b0c-bb24-94573976ae60
let
	n = 100
	data = StructArray(a=collect(range(0,step=0.01,length=n)), b=collect(range(0,step=0.01,length=n).^3))

	rs = RectSelection(poly=(;color=:orange, alpha=0.3))
	selected = selected_data(data, rs)
	
	fplt = FPlot(data, (@o _.a), (@o _.b); color=(@o _.b), colormap=Ref(:turbo))

	fig = Figure()
	axplot(scatter, widgets=[rs])(fig[1,1], fplt)
	axplot(scatter, widgets=[rs])(fig[1,2], (@set fplt[1] = @o 1/_.a))
	axplot(scatter, widgets=[rs])(fig[2,1], (@set fplt[2] = @o 1/_.b))

	sum_str = @lift let
		cnt = length($selected)
		sum_a = @p sum(_.a, $selected)
		f"selected {cnt} elements\ntotal of a values is {sum_a:.2f}"
	end
	Label(fig[2,2], sum_str, tellheight=false, tellwidth=false)

	fig #|> display
end;

# ╔═╡ 45bbf2d4-729f-487d-9b21-07f6b738ec2c
md"""
These examples demonstrate every feature of `RectSelection` separately for clarify, but of course the can be utilized all at once.
"""

# ╔═╡ 3fd8c3ab-a27e-4c1f-b799-26baee34747f
md"""
### Using `FPlot` in packages
"""

# ╔═╡ c3d07524-d2ee-4f00-9707-000dc5b33096
md"""
Above, we saw how composable `FPlot` is from the enduser PoV. This object is designed to also provide a convenient way to define specialized reusable plots.\
A couple of `FPlot`-based plots are defined in the `VLBIPlots.jl` package, and here we'll explore what niceties this brings.

First, load some radio astronomy (VLBI) data – this is a regular Julian vector of NamedTuples, effectively the simplest table:
"""

# ╔═╡ 20855fc2-3b76-4eae-a144-5692d47cf948
visdata = @p VLBI.load(joinpath(pkgdir(VLBI), "test/data/SR1_3C279_2017_101_hi_hops_netcal_StokesI.uvfits")) |> uvtable |> filter(_.stokes ∈ (:LL, :RR))

# ╔═╡ 501717dc-0c47-42b1-8fc6-40222ef69973
md"""
`UVPlot(...)` is a function defined in `VLBIPlots.jl` ([see the defition](https://github.com/JuliaAPlavin/VLBIPlots.jl/blob/master/src/uvplot.jl)).
In the most basic form, it takes a dataset and returns an `FPlot` object that defines how it should be displayed:
"""

# ╔═╡ 88ead22e-583f-41a7-84ed-40d338c13e1f
UVPlot(visdata)

# ╔═╡ 56957d31-a940-492a-a736-4457e983c76c
md"""
As you already know, the `FPlot` object contains the dataset:
"""

# ╔═╡ 792192f7-3412-4a9d-aa9a-72b71f1bffa9
UVPlot(visdata).data === visdata

# ╔═╡ c556e1f4-7522-46da-841e-a62ad8fa448b
md"""
, the function mapping dataset elements to Makie arguments:
"""

# ╔═╡ 2b3c9d91-3639-4e90-b1a0-4fffd895e3f6
UVPlot(visdata)[1]

# ╔═╡ 3084bf99-632a-48e8-a590-2b100e1fedb4
md"""
, and the Axis attributes:
"""

# ╔═╡ 243ee4b1-4a6d-461c-8afc-113827bd78b3
UVPlot(visdata).axis

# ╔═╡ 7c39f234-60bb-40ab-ba17-c7b3a56cc6c9
md"""
Plotting this object displays the dataset in a way colloquially know as the "uv plot" in the VLBI community:
"""

# ╔═╡ 9b657748-09d9-44f5-8272-8dd7f286bc31
axplot(scatter)(UVPlot(visdata))

# ╔═╡ 5bc1889c-5ee7-4be6-9655-d9eafa6351f4
md"""
This – the most basic `FPlot` usage – is already convenient for bundling everything needed for a custom plot into one object. \
Now, let's see what we mean by "composable".

Here, we first create an `FPlot` object that contains the data and some plotting attributes. But it doesn't specify what to plot as x/y coordinates yet. \
Then, we pass this object to functions like `UVPlot`, and they add the missing pieces: x/y mappings and axis attributes:
"""

# ╔═╡ e464682f-9d1b-44f1-87be-a3724851027b
let
	fig = Figure(size=(1000, 400))

	fplt = FPlot(visdata, color=(@o _.datetime |> yeardecimal), marker='∘')
	
	axplot(scatter)(fig[1,1], UVPlot(fplt), markersize=20)
	axplot(scatter)(fig[1,2], RadPlot(fplt), markersize=10)

	fig
end

# ╔═╡ 2908194c-a67f-4170-8d5e-964690d458aa
md"""
This approach is very natural for plotting multiple views of the same dataset. Some attributes/mappings should be the same – they are passed to the original `FPlot` call; others differ from one plot to another – they go into individual plot calls.
"""

# ╔═╡ d60114b3-59d6-4187-a942-b299ea56e6fd
html"""<div style="height: 60em"></div>"""

# ╔═╡ a78e9cb0-1a79-4b30-9f8a-193345b9fb6e
md"""
Imports
"""

# ╔═╡ 11c64458-fe3e-48e1-b83a-98785e1cd8fe
TableOfContents(depth=4)

# ╔═╡ 8681f282-2045-415d-a0ac-03143526e5c7
html"""<style>
video {
	width: 100%;
}
</style>"""

# ╔═╡ 0956d1bc-4256-4672-bedf-8483851a1ebd


# ╔═╡ a1d0bb31-fce8-4056-88ec-724421ee830a


# ╔═╡ b2a6a21a-bd9e-4930-86d5-ef76b9ec9fd0


# ╔═╡ 45cc208a-3c78-439c-9985-a372ca456efb
md"""
Nothing to see below... Just some extra/wip stuff.
"""

# ╔═╡ 17e6c4b6-19b0-4a17-a6b4-4fb4a356b175


# ╔═╡ 21cb8414-0da6-4333-80c5-f14e6250ffcc
let
	fig = Figure()
	ax = Axis(fig[1,1])
	lines!(FPlot(1:10, (@o _+1), (@o _^2), color=Ref(:red)), label="MyPlot")
	lines!(FPlot(1:10, (@o _+1), (@o 10+_^2)), color=:blue, label="abc")
	axislegend()
	fig
end

# ╔═╡ e731bc52-4338-4566-8e5c-74101be4f5eb
let
	fig = Figure()
	ax = Axis(fig[1,1])
	lines!(FPlot(1:10, (@o _+1), (@o _^2)), label="MyPlot")
	lines!(FPlot(1:10, (@o _+1), (@o 10+_^2)), label="abc")
	axislegend()
	fig
end

# ╔═╡ ca0a617b-f34d-4be1-8d88-987a1357a416
axplot(lines)(FPlot(1:10, (@o (_+1, _^2))))

# ╔═╡ 5de0f3b5-4957-4ed8-9cdb-05d9aaa873d1
axplot(barplot)(FPlot(1:10, (@o _+1)))

# ╔═╡ 8b90b48f-ea6e-48b6-8c19-223014cbe6db
axplot(lines)(FPlot(1:10, (@o _^2)))

# ╔═╡ 2bbc8b55-efb1-4e87-b38b-923f74d6c972
let
	scatter(rand(10))
	lines!(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
	current_figure()
end

# ╔═╡ 9eb5bb10-0449-4da7-8a98-78ff91e463dd
lines(FPlot(1:10, x->x+1, x->x^2, color=x->sqrt(x)), linewidth=15)

# ╔═╡ d516f76b-f03d-459b-9e67-b73a44464b57
axplot(barplot)(FPlot(1:10, (@o _), (@o _^2))), axplot(barplot)(FPlot(1:10, (@o _), (@o _^2)), direction=:x)

# ╔═╡ 1a4cc0d0-d6cd-48bf-ac8a-0416b10c470a
axplot(barplot)(FPlot(1:10, string, (@o _^2)))

# ╔═╡ d715528e-166b-43e6-b7d1-74e8b9381c74
let fp = FPlot(1:10, (@o _), (@o MCM.:±(_^2, 5/√_)))
	axplot(lines)(fp)
	rangebars!(fp)
	current_figure()
end

# ╔═╡ d5b179ba-6e05-479b-8c01-8e7759890d30
axplot(rangebars)(FPlot(1:10, (@o _), (@o _^2 ± 5/√_))), axplot(rangebars)(FPlot(1:10, (@o _^2 ± 5/√_), (@o _)), direction=:x)

# ╔═╡ f493d9f9-4955-4f41-86ed-3d4ae219dab0
let fp = FPlot(1:10, (@o _*u"m"), (@o MCM.:±(_^2, 5/√_)))
	axplot(lines)(fp)
	# rangebars!(fp)
	current_figure()
end

# ╔═╡ 027fc72e-234e-4948-a93a-bdca499cbcca
let fp = FPlot(StructArray(x=(1:10)u"m", y=.√(1:10)), (@o ustrip(u"cm", _.x)), (@o _.y))
	axplot(lines)(fp)
	# rangebars!(fp)
	current_figure()
end

# ╔═╡ 5589e73d-5e8d-4fdf-a4a6-95f6d5c1727c
axplot(lines)(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))

# ╔═╡ 28b836f0-e24f-479c-8d4e-a5f8aaa86d09
let 
	fig,ax,plt = lines(FPlot(1:10, x->x+1, x->x^2, color=x->sqrt(x)), linewidth=15)
	Colorbar(fig[1,2], plt)
	current_figure()
end

# ╔═╡ ac7195a0-ddc0-4012-9af1-c80188525beb
let
	fplt = FPlot(StructArray(a=rand(100), b=randn(100)), (@o _.a), (@o _.b))
	fig = Figure()
	axplot(scatter)(fig[1,1], fplt)
	multiplot(fig[0,1], (Hist, VLines => (ymin=0, ymax=0.06, linewidth=0.5)), fplt, normalization=:pdf)
	multiplot(fig[1,2], (Hist, HLines => (xmin=0, xmax=0.06, linewidth=0.5)), fplt, normalization=:pdf, direction=:x)
	colsize!(fig.layout, 2, Relative(0.2))
	rowsize!(fig.layout, 0, Relative(0.2))
	fig
end

# ╔═╡ b8d27a64-07e7-4088-84f2-78bd68ab0806


# ╔═╡ b25a5e7f-fafb-429d-a2cf-8c74bd3439d7
density(randn(1000), direction=:y)

# ╔═╡ 831c56f8-eb28-4e4a-a4c4-0667e3011636
hist(randn(1000), direction=:x)

# ╔═╡ ab7c42d9-2d14-4c69-a385-5093dcdf34df
struct MyObj end

# ╔═╡ 3f902ccf-7dc0-4c63-a4cd-ce0cb6fb2f5a
# Makie.used_attributes(T::Type{<:Plot}, ::MyObj) = Tuple(Makie.attribute_names(T))

# ╔═╡ bcba782a-e3ac-43b7-aac6-72dc9e621c5d
Makie.convert_arguments(ct::Type{<:AbstractPlot}, m::MyObj) = Makie.convert_arguments(ct, FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))

# ╔═╡ a010327f-2e49-42b7-a291-1ec09da63a61
axplot(lines)(MyObj())

# ╔═╡ d9f47d92-c1b7-48dd-a5dc-88226c02edd5
axplot(lines)(MyObj(); linewidth=15)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AccessorsExtra = "33016aad-b69d-45be-9359-82a41f556fd4"
DataManipulation = "38052440-ad76-4236-8414-61389b2c5143"
DateFormats = "44557152-fe0a-4de1-8405-416d90313ce6"
GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a"
IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
MakieExtra = "54e234d5-9986-40d8-815f-a5e42de435f6"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PyFormattedStrings = "5f89f4a4-a228-4886-b223-c468a82ed5b9"
StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"
VLBIFiles = "c1ebf4c8-f9d4-409a-8daf-7009448f4e6e"
VLBIPlots = "0260e397-8112-41bf-b55a-6b4577718f00"

[compat]
AccessorsExtra = "~0.1.94"
DataManipulation = "~0.1.19"
DateFormats = "~0.1.19"
GLMakie = "~0.13"
IntervalSets = "~0.7.10"
MakieExtra = "~0.2"
PlutoUI = "~0.7.61"
PyFormattedStrings = "~0.1.12"
StructArrays = "~0.7"
Unitful = "~1.23"
VLBIFiles = "~0.3.35"
VLBIPlots = "~0.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.10"
manifest_format = "2.0"
project_hash = "6d7c6d77bc3d14bf954d0f08a2be9fdab849767f"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "856ecd7cebb68e5fc87abecd2326ad59f0f911f3"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.43"
weakdeps = ["AxisKeys", "IntervalSets", "LinearAlgebra", "StaticArrays", "StructArrays", "Test", "Unitful"]

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

[[deps.AccessorsExtra]]
deps = ["Accessors", "CompositionsBase", "ConstructionBase", "DataPipes", "InverseFunctions", "LinearAlgebra", "Reexport"]
git-tree-sha1 = "5c6d50ec5b3a3fc2e87d0ce26b934fb87ec4d41b"
uuid = "33016aad-b69d-45be-9359-82a41f556fd4"
version = "0.1.102"

    [deps.AccessorsExtra.extensions]
    ColorTypesExt = "ColorTypes"
    DateFormatsExt = "DateFormats"
    DatesExt = "Dates"
    DictArraysExt = "DictArrays"
    DictionariesExt = "Dictionaries"
    DistributionsExt = "Distributions"
    DomainSetsExt = "DomainSets"
    FlexiGroupsExt = "FlexiGroups"
    FlexiMapsExt = "FlexiMaps"
    FlexiMapsStructArraysExt = ["FlexiMaps", "StructArrays"]
    MakieExt = "Makie"
    SkipperExt = "Skipper"
    StaticArraysExt = "StaticArrays"
    StatisticsExt = "Statistics"
    StatsBaseExt = "StatsBase"
    StructArraysExt = "StructArrays"
    TablesExt = "Tables"
    TestExt = "Test"
    URIsExt = "URIs"
    UnitfulExt = "Unitful"

    [deps.AccessorsExtra.weakdeps]
    ColorTypes = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
    DateFormats = "44557152-fe0a-4de1-8405-416d90313ce6"
    Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
    DictArrays = "e9958f2c-b184-4647-9c5a-224a61f6a14b"
    Dictionaries = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    DomainSets = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
    FlexiGroups = "1e56b746-2900-429a-8028-5ec1f00612ec"
    FlexiMaps = "6394faf6-06db-4fa8-b750-35ccc60383f7"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    Skipper = "fc65d762-6112-4b1c-b428-ad0792653d81"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
    StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    URIs = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "7e35fca2bdfba44d797c53dfe63a51fabf39bfc0"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.4.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AdaptivePredicates]]
git-tree-sha1 = "7e651ea8d262d2d74ce75fdf47c4d63c07dba7a6"
uuid = "35492f91-a3bd-45ad-95db-fcad7dcfedb7"
version = "1.2.0"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e092fa223bf66a3c41f9c022bd074d916dc303e7"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["PrecompileTools", "SIMD", "TranscodingStreams"]
git-tree-sha1 = "a8f503e8e1a5f583fbef15a8440c8c7e32185df2"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.1.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "4126b08903b777c88edf1754288144a0492c05ad"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.8"

[[deps.AxisKeys]]
deps = ["IntervalSets", "LinearAlgebra", "NamedDims", "Tables"]
git-tree-sha1 = "74f4672d77b0a98c808880a556768fe2ccf99b13"
uuid = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
version = "0.2.17"

    [deps.AxisKeys.extensions]
    AbstractFFTsExt = "AbstractFFTs"
    ChainRulesCoreExt = "ChainRulesCore"
    CovarianceEstimationExt = "CovarianceEstimation"
    InterpolationsExt = "Interpolations"
    InvertedIndicesExt = "InvertedIndices"
    LazyStackExt = "LazyStack"
    OffsetArraysExt = "OffsetArrays"
    StatisticsExt = "Statistics"
    StatsBaseExt = "StatsBase"

    [deps.AxisKeys.weakdeps]
    AbstractFFTs = "621f4979-c628-5d54-868e-fcf4e3e8185c"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    CovarianceEstimation = "587fd27a-f159-11e8-2dae-1979310e6154"
    Interpolations = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
    InvertedIndices = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
    LazyStack = "1fad7336-0346-5a1a-a56f-a06ba010965b"
    OffsetArrays = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
    StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[[deps.AxisKeysExtra]]
deps = ["AxisKeys", "DataPipes", "Reexport", "StructArrays"]
git-tree-sha1 = "bfb0b8d0d66b14f5551808994c470e449fd7b21c"
uuid = "b7a0d2b7-1990-46dc-b5dd-87820ecd1b09"
version = "0.1.26"

    [deps.AxisKeysExtra.extensions]
    ComradeBaseExt = ["ComradeBase", "Unitful"]
    DimensionalDataExt = "DimensionalData"
    GeoMakieExt = ["GeoMakie", "Makie"]
    MakieExt = "Makie"
    RectiGridsExt = "RectiGrids"
    UnitfulExt = "Unitful"
    VLBISkyModelsExt = "VLBISkyModels"

    [deps.AxisKeysExtra.weakdeps]
    ComradeBase = "6d8c423b-a35f-4ef1-850c-862fe21f82c4"
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"
    GeoMakie = "db073c08-6b98-4ee5-b6a4-5efafb3259c6"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    RectiGrids = "8ac6971d-971d-971d-971d-971d5ab1a71a"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"
    VLBISkyModels = "d6343c73-7174-4e0f-bb64-562643efbeca"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BaseDirs]]
git-tree-sha1 = "bca794632b8a9bbe159d56bf9e31c422671b35e0"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.3.2"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CFITSIO]]
deps = ["CFITSIO_jll"]
git-tree-sha1 = "8c6b984c3928736d455eb53a6adf881457825269"
uuid = "3b1b4be9-1499-4b22-8d78-7db3344d1961"
version = "1.7.2"

[[deps.CFITSIO_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "LibCURL_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "15e80be798d7711411f4ac4273144cdb2a89eb2f"
uuid = "b3e40c51-02ae-5482-8a39-3ace5868dcf4"
version = "4.6.2+0"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"

[[deps.CRlibm]]
deps = ["CRlibm_jll"]
git-tree-sha1 = "66188d9d103b92b6cd705214242e27f5737a1e5e"
uuid = "96374032-68de-5a5b-8d9e-752f78720389"
version = "1.0.2"

[[deps.CRlibm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e329286945d0cfc04456972ea732551869af1cfc"
uuid = "4e9b3aee-d8a1-5a3d-ad8b-7d824db253f0"
version = "1.0.1+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a21c5464519504e41e0cbc91f0188e8ca23d7440"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.5+1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "e4c6a16e77171a5f5e25e9646617ab1c276c5607"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.26.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON"]
git-tree-sha1 = "07da79661b919001e6863b81fc572497daa58349"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b0fd3f56fa442f81e0a47815c92245acfaaa4e34"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "37ea44092930b1811e666c3bc38065d7d87fcc74"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.Combinatorics]]
git-tree-sha1 = "c761b00e7755700f9cdf5b02039939d1359330e1"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.1.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ComputePipeline]]
deps = ["Observables", "Preferences"]
git-tree-sha1 = "76dab592fa553e378f9dd8adea16fe2591aa3daa"
uuid = "95dc2771-c249-4cd0-9c9f-1f3b4330693c"
version = "0.1.6"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataManipulation]]
deps = ["Accessors", "AccessorsExtra", "DataPipes", "Dictionaries", "FlexiGroups", "FlexiMaps", "InverseFunctions", "Reexport", "Skipper", "StructArrays"]
git-tree-sha1 = "483af7c3ea440a9a0dd3c33ca1cc86661ed28d54"
uuid = "38052440-ad76-4236-8414-61389b2c5143"
version = "0.1.21"
weakdeps = ["IntervalSets"]

    [deps.DataManipulation.extensions]
    IntervalSetsExt = "IntervalSets"

[[deps.DataPipes]]
git-tree-sha1 = "3fb39158bc35c984cac5edb1ff55daa88a4b5074"
uuid = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
version = "0.3.19"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "e357641bb3e0638d353c4b29ea0e40ea644066a6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.3"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DateFormats]]
deps = ["Dates", "Reexport"]
git-tree-sha1 = "a73965314cb45f0ac9cc617267cb3f1d4f617742"
uuid = "44557152-fe0a-4de1-8405-416d90313ce6"
version = "0.1.20"

    [deps.DateFormats.extensions]
    AccessorsExt = "Accessors"
    IntervalSetsExt = "IntervalSets"
    InverseFunctionsExt = "InverseFunctions"
    StatisticsExt = "Statistics"
    TimeZonesExt = "TimeZones"

    [deps.DateFormats.weakdeps]
    Accessors = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
    TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "473e9afc9cf30814eb67ffa5f2db7df82c3ad9fd"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.16.2+0"

[[deps.DelaunayTriangulation]]
deps = ["AdaptivePredicates", "EnumX", "ExactPredicates", "Random"]
git-tree-sha1 = "c55f5a9fd67bdbc8e089b5a3111fe4292986a8e8"
uuid = "927a84f5-c5f4-47a5-9785-b46e178433df"
version = "1.6.6"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "a55766a9c8f66cf19ffcdbdb1444e249bb4ace33"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.4.6"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "fbcc7610f6d8348428f722ecbe0e6cfe22e672c6"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.123"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EnumX]]
git-tree-sha1 = "c49898e8438c828577f04b92fc9368c388ac783c"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.7"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a4be429317c42cfae6a7fc03c31bad1970c310d"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+1"

[[deps.ExactPredicates]]
deps = ["IntervalArithmetic", "Random", "StaticArrays"]
git-tree-sha1 = "83231673ea4d3d6008ac74dc5079e77ab2209d8f"
uuid = "429591f6-91af-11e9-00e2-59fbe8cec110"
version = "2.2.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "27af30de8b5445644e8ffe3bcb0d72049c089cf1"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.7.3+0"

[[deps.Extents]]
git-tree-sha1 = "b309b36a9e02fe7be71270dd8c0fd873625332b4"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.6"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "01ba9d15e9eae375dc1eb9589df76b3572acd3f2"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "8.0.1+0"

[[deps.FFTA]]
deps = ["AbstractFFTs", "DocStringExtensions", "LinearAlgebra", "MuladdMacro", "Primes", "Random", "Reexport"]
git-tree-sha1 = "65e55303b72f4a567a51b174dd2c47496efeb95a"
uuid = "b86e33f2-c0db-4aa1-a6e0-ab43e668529e"
version = "0.3.1"

[[deps.FITSIO]]
deps = ["CFITSIO", "Printf", "Reexport", "Tables"]
git-tree-sha1 = "f57de3f533590c785210893030736dc11c4a4afb"
uuid = "525bcba6-941b-5504-bd06-fd0dc1a4d2eb"
version = "0.17.5"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "6522cfb3b8fe97bec632252263057996cbd3de20"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.18.0"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport"]
git-tree-sha1 = "a1b2fbfe98503f15b665ed45b3d149e5d8895e4c"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.9.0"

    [deps.FilePaths.extensions]
    FilePathsGlobExt = "Glob"
    FilePathsURIParserExt = "URIParser"
    FilePathsURIsExt = "URIs"

    [deps.FilePaths.weakdeps]
    Glob = "c27321d9-0574-5035-807b-f59d2c89b15c"
    URIParser = "30578b45-9adc-5946-b283-645ec420af67"
    URIs = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "3bab2c5aa25e7840a4b065805c0cdfc01f3068d2"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.24"
weakdeps = ["Mmap", "Test"]

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2f979084d1e13948a3352cf64a25df6bd3b4dca3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.16.0"
weakdeps = ["PDMats", "SparseArrays", "StaticArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStaticArraysExt = "StaticArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.FlexiGroups]]
deps = ["AccessorsExtra", "Combinatorics", "DataPipes", "Dictionaries", "FlexiMaps"]
git-tree-sha1 = "2c597013338760e163cf84514cead7bf8d016f46"
uuid = "1e56b746-2900-429a-8028-5ec1f00612ec"
version = "0.1.29"

    [deps.FlexiGroups.extensions]
    AxisKeysExt = "AxisKeys"
    CategoricalArraysExt = "CategoricalArrays"
    OffsetArraysExt = "OffsetArrays"
    StructArraysExt = "StructArrays"

    [deps.FlexiGroups.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    CategoricalArrays = "324d7699-5711-5eae-9e2f-1d82baa6b597"
    OffsetArrays = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"

[[deps.FlexiMaps]]
deps = ["Accessors", "DataPipes", "InverseFunctions"]
git-tree-sha1 = "c2e79264c5e749d099d7ae854f64ec73f2f9e3e9"
uuid = "6394faf6-06db-4fa8-b750-35ccc60383f7"
version = "0.1.29"
weakdeps = ["AxisKeys", "Dictionaries", "IntervalSets", "StructArrays", "Unitful"]

    [deps.FlexiMaps.extensions]
    AxisKeysExt = "AxisKeys"
    DictionariesExt = "Dictionaries"
    IntervalSetsExt = "IntervalSets"
    StructArraysExt = "StructArrays"
    UnitfulExt = "Unitful"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "f85dac9a96a01087df6e3a749840015a0ca3817d"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.17.1+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "907369da0f8e80728ab49c1c7e09327bf0d6d999"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.1.1"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["BaseDirs", "ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "Mmap"]
git-tree-sha1 = "4ebb930ef4a43817991ba35db6317a05e59abd11"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.8"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.GLFW]]
deps = ["GLFW_jll"]
git-tree-sha1 = "af06f66cca2b698ab9c482de55977ff8178d025e"
uuid = "f7f18e0c-5ee9-5ccd-a5bf-e8befd85ed98"
version = "3.4.6"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "b7bfd56fa66616138dfe5237da4dc13bbd83c67f"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.1+0"

[[deps.GLMakie]]
deps = ["ColorTypes", "Colors", "FileIO", "FixedPointNumbers", "FreeTypeAbstraction", "GLFW", "GeometryBasics", "LinearAlgebra", "Makie", "Markdown", "MeshIO", "ModernGL", "Observables", "PrecompileTools", "Printf", "ShaderAbstractions", "StaticArrays"]
git-tree-sha1 = "56335175a66c30ca0e503ad717d366cd9e1663b1"
uuid = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a"
version = "0.13.8"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "IterTools", "LinearAlgebra", "PrecompileTools", "Random", "StaticArrays"]
git-tree-sha1 = "1f5a80f4ed9f5a4aada88fc2db456e637676414b"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.10"

    [deps.GeometryBasics.extensions]
    GeometryBasicsGeoInterfaceExt = "GeoInterface"

    [deps.GeometryBasics.weakdeps]
    GeoInterface = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"

[[deps.GettextRuntime_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll"]
git-tree-sha1 = "45288942190db7c5f760f59c04495064eedf9340"
uuid = "b0724c58-0f36-5564-988d-3bb0596ebc4a"
version = "0.22.4+0"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "GettextRuntime_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "24f6def62397474a297bfcec22384101609142ed"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.86.3+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "93d5c27c8de51687a2c70ec0716e6e76f298416f"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.2"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "f923f9a774fcf3f5cb761bfa43aeadd689714813"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.1+0"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "68c173f4f449de5b438ee67ed0c9c748dc31a2ec"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.28"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "e12629406c6c4442539436581041d372d69c55ba"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.12"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "dcc8d0cd653e55213df9b75ebc6fe4a8d3254c65"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.2.2+0"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntegerMathUtils]]
git-tree-sha1 = "4c1acff2dc6b6967e7e750633c50bc3b8d83e617"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InterferometricModels]]
deps = ["AccessorsExtra", "DataPipes", "IntervalSets", "LinearAlgebra", "Random", "StaticArrays", "StructHelpers", "Unitful", "UnitfulAstro"]
git-tree-sha1 = "245c258c5d865b23fa5b02fdcd508a309a6d7d33"
uuid = "b395d269-c2ec-4df6-b679-36919ad600ca"
version = "0.1.34"

    [deps.InterferometricModels.extensions]
    ComradeBaseExt = "ComradeBase"

    [deps.InterferometricModels.weakdeps]
    ComradeBase = "6d8c423b-a35f-4ef1-850c-862fe21f82c4"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "MacroTools", "OpenBLASConsistentFPCSR_jll", "Printf", "Random", "RoundingEmulator"]
git-tree-sha1 = "02b61501dbe6da3b927cc25dacd7ce32390ee970"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "1.0.2"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticArblibExt = "Arblib"
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticIntervalSetsExt = "IntervalSets"
    IntervalArithmeticLinearAlgebraExt = "LinearAlgebra"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"
    IntervalArithmeticSparseArraysExt = "SparseArrays"

    [deps.IntervalArithmetic.weakdeps]
    Arblib = "fb37089c-8514-4489-9461-98f9c8763369"
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.IntervalSets]]
git-tree-sha1 = "d966f85b3b7a8e49d034d27a189e9a4874b4391a"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.13"

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

    [deps.IntervalSets.weakdeps]
    Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "b3ad4a0255688dcb895a52fafbaae3023b588a90"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.4.0"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "9496de8fb52c224a2e3f9ff403947674517317d9"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.6"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6893345fd6658c8e475d40155789f4860ac3b21"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.4+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTA", "Interpolations", "StatsBase"]
git-tree-sha1 = "4260cfc991b8885bf747801fb60dd4503250e478"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.11"

[[deps.KwdefHelpers]]
deps = ["Accessors"]
git-tree-sha1 = "5078865e4949bb95d4dd2197504176ca849f7c48"
uuid = "80d9ef48-13f8-4f87-9333-d4c97b041895"
version = "0.1.0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "059aabebaa7c82ccb853dd4a0ee9d17796f7e1bc"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eb62a3deb62fc6d8822c0c4bef73e4412419c5d8"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.8+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c602b1127f4751facb671441ca72715cc95938a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.3+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c8da7e6a91781c41a863611c7e966098d783c57a"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.4.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "97bbca976196f2a1eb9607131cb108c69ec3f8a6"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.3+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "f04133fe05eff1667d2054c53d59f9122383fe05"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.2+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d0205286d9eceadc518742860bf23f703779a3d6"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.3+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Makie]]
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "ComputePipeline", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "Pkg", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "Showoff", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "d1b974f376c24dad02c873e951c5cd4e351cd7c2"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.24.8"

    [deps.Makie.extensions]
    MakieDynamicQuantitiesExt = "DynamicQuantities"

    [deps.Makie.weakdeps]
    DynamicQuantities = "06fc5a27-2a28-4c7c-a15d-362465fb6821"

[[deps.MakieExtra]]
deps = ["AccessorsExtra", "DataManipulation", "InverseFunctions", "KwdefHelpers", "LinearAlgebra", "Makie", "NonNegLeastSquares", "PyFormattedStrings", "Reexport", "StructHelpers"]
git-tree-sha1 = "399e52791f06de6f8892925201ea6a082ebb5210"
uuid = "54e234d5-9986-40d8-815f-a5e42de435f6"
version = "0.2.1"

    [deps.MakieExtra.extensions]
    GLMakieExt = "GLMakie"
    GeoMakieExt = "GeoMakie"

    [deps.MakieExtra.weakdeps]
    GLMakie = "e9467ef8-e4e7-5192-8a1a-b1aee30e663a"
    GeoMakie = "db073c08-6b98-4ee5-b6a4-5efafb3259c6"

[[deps.MappedArrays]]
git-tree-sha1 = "0ee4497a4e80dbd29c058fcee6493f5219556f40"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.3"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "UnicodeFun"]
git-tree-sha1 = "7eb8cdaa6f0e8081616367c10b31b9d9b34bb02a"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MeshIO]]
deps = ["ColorTypes", "FileIO", "GeometryBasics", "Printf"]
git-tree-sha1 = "c009236e222df68e554c7ce5c720e4a33cc0c23f"
uuid = "7269a6da-0436-5bbc-96c2-40638cbb6118"
version = "0.5.3"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.ModernGL]]
deps = ["Libdl"]
git-tree-sha1 = "ac6cb1d8807a05cf1acc9680e09d2294f9d33956"
uuid = "66fc600b-dfda-50eb-8b99-91cfa97b1301"
version = "1.1.8"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.NamedDims]]
deps = ["LinearAlgebra", "Statistics"]
git-tree-sha1 = "f9e4a49ecd1ea2eccfb749a506fa882c094152b4"
uuid = "356022a1-0364-5f58-8944-0da4b18d706f"
version = "1.2.3"

    [deps.NamedDims.extensions]
    AbstractFFTsExt = "AbstractFFTs"
    ChainRulesCoreExt = "ChainRulesCore"
    CovarianceEstimationExt = "CovarianceEstimation"
    TrackerExt = "Tracker"

    [deps.NamedDims.weakdeps]
    AbstractFFTs = "621f4979-c628-5d54-868e-fcf4e3e8185c"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    CovarianceEstimation = "587fd27a-f159-11e8-2dae-1979310e6154"
    Requires = "ae029012-a4dd-5104-9daa-d747884805df"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonNegLeastSquares]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "cdc11138e74a0dd0b82e7d64eb1350fdf049d3b1"
uuid = "b7351bd1-99d9-5c5d-8786-f205a815c4d7"
version = "0.4.1"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6aa4566bb7ae78498a5e68943863fa8b5231b59"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.6+0"

[[deps.OpenBLASConsistentFPCSR_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "567515ca155d0020a45b05175449b499c63e7015"
uuid = "6cdc7f73-28fd-5e50-80fb-958a8875b1af"
version = "0.3.29+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "df9b7c88c2e7a2e77146223c526bf9e236d5f450"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.4.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.5+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c9cbeda6aceffc52d8a0017e71db27c7a7c0beaf"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.5+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e2bb57a313a74b8104064b7efd01406c0a50d2ff"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.6.1+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "e4cff168707d441cd6bf3ff7e4832bdf34278e4a"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.37"
weakdeps = ["StatsBase"]

    [deps.PDMats.extensions]
    StatsBaseExt = "StatsBase"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "cf181f0b1e6a18dfeb0ee8acc4a9d1672499626c"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.4"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "bc5bf2ea3d5351edf285a06b0016788a121ce92c"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.1"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0662b083e11420952f2e62e17eddae7fc07d5997"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.57.0+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "26ca162858917496748aad52bb5d3be4d26a228a"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.4"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "3ac7038a98ef6977d44adeadc73cc6f596c08109"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.79"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "25cdd1d20cd005b52fc12cb6be3f75faaf59bb9b"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "fbb92c6c56b34e1a2c4c36058f68f332bec840e7"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.PyFormattedStrings]]
deps = ["PrecompileTools", "Printf"]
git-tree-sha1 = "4edb7868d6a1c9ef22c8132c4aa1857e56bd4a84"
uuid = "5f89f4a4-a228-4886-b223-c468a82ed5b9"
version = "0.1.13"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "472daaa816895cb7aee81658d4e7aec901fa1106"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.2"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9da16da70037ba9d701192e27befedefb91ec284"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.2"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RectiGrids]]
deps = ["AxisKeys", "ConstructionBase", "Random"]
git-tree-sha1 = "d7cef068f5463910bcd09d005ff9212489cfeceb"
uuid = "8ac6971d-971d-971d-971d-971d5ab1a71a"
version = "0.1.19"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "5b3d50eb374cea306873b371d3f8d3915a018f0b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.9.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "e24dc23107d426a096d3eae6c165b921e74c18e4"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.2"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.ShaderAbstractions]]
deps = ["ColorTypes", "FixedPointNumbers", "GeometryBasics", "LinearAlgebra", "Observables", "StaticArrays"]
git-tree-sha1 = "818554664a2e01fc3784becb2eb3a82326a604b6"
uuid = "65257c39-d410-5151-9873-9b3e5be5013e"
version = "0.5.0"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Statistics"]
git-tree-sha1 = "3949ad92e1c9d2ff0cd4a1317d5ecbba682f4b92"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.1"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "be8eeac05ec97d379347584fa9fe2f5f76795bcb"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.5"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "0494aed9501e7fb65daba895fb7fd57cc38bc743"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.5"

[[deps.Skipper]]
git-tree-sha1 = "c020b7436e4f74e6207eba22b4a917f5184a310a"
uuid = "fc65d762-6112-4b1c-b428-ad0792653d81"
version = "0.1.16"
weakdeps = ["Accessors", "AxisKeys", "Dictionaries", "Makie"]

    [deps.Skipper.extensions]
    AccessorsExt = "Accessors"
    AxisKeysExt = "AxisKeys"
    DictionariesExt = "Dictionaries"
    MakieExt = "Makie"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5acc6a41b3082920f79ca3c759acbcecf18a8d78"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.7.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "4f96c596b8c8258cc7d3b19797854d368f243ddc"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.4"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "be1cf4eb0ac528d96f5115b4ed80c26a8d8ae621"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.2"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "0f529006004a8be48f1be25f3451186579392d47"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.17"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "aceda6f4e598d331548e04cc6b2124a6148138e3"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.10"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "91f091a8716a6bb38417a6e6f274602a19aaa685"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.2"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "a2c37d815bf00575332b7bd0389f771cb7987214"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.7.2"

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = ["GPUArraysCore", "KernelAbstractions"]
    StructArraysLinearAlgebraExt = "LinearAlgebra"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

    [deps.StructArrays.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.StructHelpers]]
deps = ["ConstructionBase"]
git-tree-sha1 = "a74c988de377a551b85de77343c33b70134df240"
uuid = "4093c41a-2008-41fd-82b8-e3f9d02b504f"
version = "1.4.0"

[[deps.StructUtils]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "28145feabf717c5d65c1d5e09747ee7b1ff3ed13"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.6.3"

    [deps.StructUtils.extensions]
    StructUtilsMeasurementsExt = ["Measurements"]
    StructUtilsTablesExt = ["Tables"]

    [deps.StructUtils.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "PrecompileTools", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "98b9352a24cb6a2066f9ababcc6802de9aed8ad8"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.6"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Uncertain]]
deps = ["Accessors", "LinearAlgebra"]
git-tree-sha1 = "8e877322335d6efeffe46722b94f8af0177d9465"
uuid = "b33f403f-199b-472b-b9d0-1cd2092892d0"
version = "0.1.17"

    [deps.Uncertain.extensions]
    FlexiJoinsExt = "FlexiJoins"
    IntervalSetsExt = "IntervalSets"
    MakieExt = "Makie"
    MakieMonteCarloMeasurementsExt = ["Makie", "MonteCarloMeasurements"]
    MeasurementsExt = "Measurements"
    MonteCarloMeasurementsExt = "MonteCarloMeasurements"
    PrintfExt = "Printf"
    StaticArraysExt = "StaticArrays"
    UnitfulExt = "Unitful"

    [deps.Uncertain.weakdeps]
    FlexiJoins = "e37f2e79-19fa-4eb7-8510-b63b51fe0a37"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d2282232f8a4d71f79e85dc4dd45e5b12a6297fb"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.23.1"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    PrintfExt = "Printf"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"
    Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.UnitfulAngles]]
deps = ["Dates", "Unitful"]
git-tree-sha1 = "79875b1f2e4bf918f0702a5980816955066d9ae2"
uuid = "6fb2a4bd-7999-5318-a3b2-8ad61056cd98"
version = "0.7.2"

[[deps.UnitfulAstro]]
deps = ["Unitful", "UnitfulAngles"]
git-tree-sha1 = "fbe44a0ade62ae5ed0240ad314dfdd5482b90b40"
uuid = "6112ee07-acf9-5e0f-b108-d242c714bf9f"
version = "1.2.2"

[[deps.VLBIData]]
deps = ["AccessorsExtra", "DataManipulation", "InterferometricModels", "IntervalSets", "Reexport", "StaticArrays", "Statistics", "StructArrays", "StructHelpers", "Uncertain", "Unitful"]
git-tree-sha1 = "39b9941f18e6b15620fb885f915f119a35201c96"
uuid = "679fc9cc-3e84-11e9-251b-cbd013bd8115"
version = "0.4.10"

    [deps.VLBIData.extensions]
    ComradeBaseExt = "ComradeBase"
    PolarizedTypesExt = "PolarizedTypes"
    VLBISkyModelsExt = "VLBISkyModels"

    [deps.VLBIData.weakdeps]
    ComradeBase = "6d8c423b-a35f-4ef1-850c-862fe21f82c4"
    PolarizedTypes = "d3c5d4cd-a8ee-40d6-aac7-e34df5a20044"
    VLBISkyModels = "d6343c73-7174-4e0f-bb64-562643efbeca"

[[deps.VLBIFiles]]
deps = ["AccessorsExtra", "AxisKeys", "DataManipulation", "DateFormats", "Dates", "DelimitedFiles", "FITSIO", "InterferometricModels", "PrecompileTools", "PyFormattedStrings", "Reexport", "StaticArrays", "Statistics", "StructArrays", "Tables", "Uncertain", "Unitful", "UnitfulAngles", "UnitfulAstro", "VLBIData"]
git-tree-sha1 = "50e41ba0cce7d74d099a0b3a967952e7f2db6a6f"
uuid = "c1ebf4c8-f9d4-409a-8daf-7009448f4e6e"
version = "0.3.36"

    [deps.VLBIFiles.extensions]
    InterpolationsExt = "Interpolations"
    PyCallExt = "PyCall"
    RectiGridsAxisKeysExtraExt = ["RectiGrids", "AxisKeysExtra"]

    [deps.VLBIFiles.weakdeps]
    AxisKeysExtra = "b7a0d2b7-1990-46dc-b5dd-87820ecd1b09"
    Interpolations = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    RectiGrids = "8ac6971d-971d-971d-971d-971d5ab1a71a"

[[deps.VLBIPlots]]
deps = ["Accessors", "AccessorsExtra", "AxisKeysExtra", "DataManipulation", "Dates", "InterferometricModels", "IntervalSets", "InverseFunctions", "LinearAlgebra", "MakieExtra", "RectiGrids", "StaticArrays", "Statistics", "Unitful", "VLBIData"]
git-tree-sha1 = "7fc6699949ce1cacf28cbb9bb1a5d1cb96c7be19"
uuid = "0260e397-8112-41bf-b55a-6b4577718f00"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "96478df35bbc2f3e1e791bc7a3d0eeee559e60e9"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.24.0+0"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "248a7031b3da79a127f14e5dc5f417e26f9f6db7"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.1.0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "9cce64c0fdd1960b597ba7ecda2950b5ed957438"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.2+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "808090ede1d41644447dd5cbafced4731c56bd2f"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.13+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "6c74ca84bbabc18c4547014765d194ff0b4dc9da"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.4+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "1a4a26870bf1e5d26cd585e38038d399d7e65706"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.8+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "75e00946e43621e09d431d9b95818ee751e6b2ef"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.2+0"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "a376af5c7ae60d29825164db40787f15c80c7c54"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.8.3+0"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll"]
git-tree-sha1 = "0ba01bc7396896a4ace8aab67db31403c71628f4"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.7+0"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "6c174ef70c96c76f4c3f4d3cfbe09d018bcd1b53"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.6+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "ed756a03e95fff88d8f738ebc2849431bdd4fd1a"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.2.0+0"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "801a858fc9fb90c11ffddee1801bb06a738bda9b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.7+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "00af7ebdc563c9217ecc67776d1bbf037dbcebf4"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.44.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "371cc681c00a3ccc3fbc5c0fb91f58ba9bec1ecf"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.13.1+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "125eedcb0a4a0bba65b657251ce1d27c8714e9d6"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.17.4+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "646634dd19587a56ee2f1199563ec056c5f228df"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.4+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e015f211ebb898c8180887012b938f3851e719ac"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.55+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "libpng_jll"]
git-tree-sha1 = "c1733e347283df07689d71d61e14be986e49e47a"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.5+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll"]
git-tree-sha1 = "11e1772e7f3cc987e9d3de991dd4f6b2602663a5"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.8+0"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "4e4282c4d846e11dce56d74fa8040130b7a95cb3"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.6.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "14cc7083fc6dff3cc44f2bc435ee96d06ed79aa7"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "10164.0.1+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e7b67590c14d487e734dcb925924c5dc43ec85f3"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "4.1.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "a1fc6507a40bf504527d0d4067d718f8e179b2b8"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.13.0+0"
"""

# ╔═╡ Cell order:
# ╟─a4c423f8-07d4-4658-b684-3324086d15dd
# ╟─1ad2f738-9ef3-4677-9f92-72cc0f670dc9
# ╟─493fa6c3-68b4-47f7-8c09-d1857d4fede0
# ╟─d092ff18-93aa-4c81-8af7-62613e074f51
# ╠═4c171005-d3e5-4678-b454-901ccc824c1e
# ╟─51648500-f070-4dff-9b3f-a82d40335860
# ╠═5bf41e25-0992-4186-84af-00d4cf3e5c6e
# ╠═7c0c7bd7-2842-47c0-8240-8beefc37de26
# ╠═e9c1096f-af1b-4005-9817-214ae7e8a5a9
# ╟─c1917d5f-791f-4c81-8bcf-63e8b6d7a83e
# ╟─d9489617-3001-47e4-94af-cdbfdb96d7d6
# ╟─fe7ebf74-4dcc-4de4-95fc-bbd1367c01a0
# ╟─37e474a3-30ac-4ada-9ddd-8fb521b76133
# ╠═77f5b4ca-1696-4f6b-8a0c-3fda885867cb
# ╟─80bf77ae-a576-45e7-9796-c993c0a87118
# ╠═0faeb906-bbf4-4304-9a52-7e15cfa72252
# ╟─975aec3e-04aa-471f-8883-dce736b2f78b
# ╟─a930e58f-8b02-4100-8bac-4bdbcad5aabd
# ╠═d93d0fa9-e5cd-4410-bee2-755cd710b3f2
# ╟─b0d7d774-e07d-4c3c-b2b6-a016710b09a0
# ╠═aebbac13-8f41-41a7-b0d9-ec8b6feef124
# ╟─06c4630a-32f4-47e2-8484-d0208d93bc17
# ╟─2c72a873-c690-46aa-a0db-bf9be62d305a
# ╠═68a418ac-b352-4594-99ad-17328f510665
# ╟─e495b551-45e9-41da-9d05-3fbd73aa7f34
# ╟─137c903b-d829-47d8-b793-fd4e053844d5
# ╠═1cfb255f-9fcc-426f-bc57-bde22eedbf6c
# ╟─46310a44-37fc-4193-b089-8049071b3331
# ╟─70bbaf38-f1d9-4373-8b2c-fdc3f49bedd7
# ╟─a3c56aa3-fb46-4f10-a7df-e96ebeee523e
# ╠═cf092210-32b6-4ea8-9c16-6ea3104d3d77
# ╟─2636263c-bc75-48e1-905c-fad4d151edc0
# ╟─038630ce-f172-459d-b953-3222c9017c8b
# ╟─73b2f789-22ad-40d1-a360-d2e294908276
# ╟─72c35d8e-516d-4925-b250-2e8a496b9540
# ╠═13a47f17-ca59-42c0-8221-97a376c7647a
# ╟─225b5175-bda1-40b2-ae90-7f8a3a83a27f
# ╟─8b79b5e9-61bd-40d5-9d78-118e8cbf7b0d
# ╠═0c3da8d7-3632-4020-b565-5ef589b56359
# ╟─addc827a-9cc2-4f8d-b0b8-4c5cc594db53
# ╟─800091fe-f1ec-4069-bbea-dbcb2420f56f
# ╠═a2c1e9b6-bd46-4b0c-bb24-94573976ae60
# ╟─45bbf2d4-729f-487d-9b21-07f6b738ec2c
# ╟─3fd8c3ab-a27e-4c1f-b799-26baee34747f
# ╟─c3d07524-d2ee-4f00-9707-000dc5b33096
# ╠═20855fc2-3b76-4eae-a144-5692d47cf948
# ╟─501717dc-0c47-42b1-8fc6-40222ef69973
# ╠═88ead22e-583f-41a7-84ed-40d338c13e1f
# ╟─56957d31-a940-492a-a736-4457e983c76c
# ╠═792192f7-3412-4a9d-aa9a-72b71f1bffa9
# ╟─c556e1f4-7522-46da-841e-a62ad8fa448b
# ╠═2b3c9d91-3639-4e90-b1a0-4fffd895e3f6
# ╟─3084bf99-632a-48e8-a590-2b100e1fedb4
# ╠═243ee4b1-4a6d-461c-8afc-113827bd78b3
# ╟─7c39f234-60bb-40ab-ba17-c7b3a56cc6c9
# ╠═9b657748-09d9-44f5-8272-8dd7f286bc31
# ╟─5bc1889c-5ee7-4be6-9655-d9eafa6351f4
# ╠═e464682f-9d1b-44f1-87be-a3724851027b
# ╟─2908194c-a67f-4170-8d5e-964690d458aa
# ╟─d60114b3-59d6-4187-a942-b299ea56e6fd
# ╟─a78e9cb0-1a79-4b30-9f8a-193345b9fb6e
# ╠═4a8ce771-7416-4ec1-a342-4820ae4ced7a
# ╠═62995210-516f-4564-a095-76d3ef966e09
# ╠═2cac5727-8bd9-4382-8b76-5e8a18e5ea70
# ╠═e7b7cbab-8095-4ea0-ac8b-d361bfe40d63
# ╠═18035dd8-736a-4ac5-8562-2cbf16b6298b
# ╠═1f789967-0357-4b61-a9af-1f72f2a28c5c
# ╠═e559ff6a-b3fc-4067-8597-0e7488b53d7f
# ╠═c756d828-7f29-4bab-9c39-0dee70116c88
# ╠═8efce9ac-d93d-4b8f-87e2-b775522da819
# ╠═d6de5f88-0b1e-4f7c-b87a-f27839c0cc9b
# ╠═11c64458-fe3e-48e1-b83a-98785e1cd8fe
# ╠═8681f282-2045-415d-a0ac-03143526e5c7
# ╠═0956d1bc-4256-4672-bedf-8483851a1ebd
# ╠═a1d0bb31-fce8-4056-88ec-724421ee830a
# ╠═b2a6a21a-bd9e-4930-86d5-ef76b9ec9fd0
# ╟─45cc208a-3c78-439c-9985-a372ca456efb
# ╠═17e6c4b6-19b0-4a17-a6b4-4fb4a356b175
# ╠═21cb8414-0da6-4333-80c5-f14e6250ffcc
# ╠═e731bc52-4338-4566-8e5c-74101be4f5eb
# ╠═ca0a617b-f34d-4be1-8d88-987a1357a416
# ╠═5de0f3b5-4957-4ed8-9cdb-05d9aaa873d1
# ╠═8b90b48f-ea6e-48b6-8c19-223014cbe6db
# ╠═2bbc8b55-efb1-4e87-b38b-923f74d6c972
# ╠═9eb5bb10-0449-4da7-8a98-78ff91e463dd
# ╠═d516f76b-f03d-459b-9e67-b73a44464b57
# ╠═1a4cc0d0-d6cd-48bf-ac8a-0416b10c470a
# ╠═d715528e-166b-43e6-b7d1-74e8b9381c74
# ╠═d5b179ba-6e05-479b-8c01-8e7759890d30
# ╠═f493d9f9-4955-4f41-86ed-3d4ae219dab0
# ╠═027fc72e-234e-4948-a93a-bdca499cbcca
# ╠═5589e73d-5e8d-4fdf-a4a6-95f6d5c1727c
# ╠═28b836f0-e24f-479c-8d4e-a5f8aaa86d09
# ╠═ac7195a0-ddc0-4012-9af1-c80188525beb
# ╠═b8d27a64-07e7-4088-84f2-78bd68ab0806
# ╠═b25a5e7f-fafb-429d-a2cf-8c74bd3439d7
# ╠═831c56f8-eb28-4e4a-a4c4-0667e3011636
# ╠═ab7c42d9-2d14-4c69-a385-5093dcdf34df
# ╠═3f902ccf-7dc0-4c63-a4cd-ce0cb6fb2f5a
# ╠═bcba782a-e3ac-43b7-aac6-72dc9e621c5d
# ╠═a010327f-2e49-42b7-a291-1ec09da63a61
# ╠═d9f47d92-c1b7-48dd-a5dc-88226c02edd5
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
