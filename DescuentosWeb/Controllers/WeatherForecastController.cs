using Microsoft.AspNetCore.Mvc;
using Microsoft.Playwright;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using System;

namespace DescuentosWeb.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProductsController : ControllerBase
    {
        [HttpGet("discounted-products")]
        public async Task<IActionResult> GetDiscountedProducts()
        {
            var products = new List<Product>();
            int maxPages = 70; 
            int startPage = 51;

            try
            {
                using (var playwright = await Playwright.CreateAsync())
                {
                    var browser = await playwright.Chromium.LaunchAsync(new BrowserTypeLaunchOptions { Headless = true });

                    // Lista de tareas para procesar páginas en paralelo
                    var tasks = Enumerable.Range(startPage, maxPages - startPage + 1).Select(async currentPage =>
                    {
                        var pageProducts = new List<Product>();
                        var page = await browser.NewPageAsync();

                        try
                        {
                            string url = $"https://www.falabella.com.pe/falabella-pe/search?Ntt=mujer&sortBy=derived.price.search%2Casc&facetSelected=true&f.derived.variant.sellerId=FALABELLA&page={currentPage}";
                            Console.WriteLine($"Procesando página {currentPage}: {url}");

                            await page.GotoAsync(url);
                            await page.WaitForSelectorAsync("#testId-searchResults-products");

                            var productNodes = await page.QuerySelectorAllAsync("#testId-searchResults-products .grid-pod");

                            foreach (var productNode in productNodes)
                            {
                                var discountNode = await productNode.QuerySelectorAsync(".discount-badge-item");
                                if (discountNode != null)
                                {
                                    var discountText = await discountNode.InnerTextAsync();
                                    if (decimal.TryParse(discountText.Replace("%", "").Replace("-", ""), out decimal discountPercentage) && discountPercentage > 70)
                                    {
                                        var nameNode = await productNode.QuerySelectorAsync(".pod-subTitle");
                                        var brandNode = await productNode.QuerySelectorAsync(".pod-title");
                                        var discountedPriceNode = await productNode.QuerySelectorAsync(".copy10");
                                        var linkNode = await productNode.QuerySelectorAsync("a.pod-link");
                                        var productUrl = await linkNode.GetAttributeAsync("href");

                                        pageProducts.Add(new Product
                                        {
                                            Name = await nameNode.InnerTextAsync(),
                                            Brand = brandNode != null ? await brandNode.InnerTextAsync() : "Sin marca",
                                            DiscountedPrice = discountedPriceNode != null ? await discountedPriceNode.InnerTextAsync() : "Precio no disponible",
                                            Discount = discountText,
                                            Link = productUrl
                                        });
                                    }
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Error procesando página {currentPage}: {ex.Message}");
                        }
                        finally
                        {
                            await page.CloseAsync();
                        }

                        return pageProducts;
                    });

                    // Ejecutar todas las tareas en paralelo
                    var results = await Task.WhenAll(tasks);

                    // Combinar resultados
                    products = results.SelectMany(p => p).ToList();

                    await browser.CloseAsync();
                }

                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener los productos.", details = ex.Message });
            }
        }
    }

    // Modelo para representar un producto
    public class Product
    {
        public string Name { get; set; }
        public string Brand { get; set; }
        public string DiscountedPrice { get; set; }
        public string Discount { get; set; }
        public string Link { get; set; }
    }
}