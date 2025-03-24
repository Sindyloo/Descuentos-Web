using Microsoft.AspNetCore.Mvc;
using Microsoft.Playwright;
using System.Collections.Generic;
using System.Threading.Tasks;
using System;
using System.Linq;

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
            int maxPages = 100;

            try
            {
                // Inicializa Playwright y abre un navegador
                using (var playwright = await Playwright.CreateAsync())
                {
                    var browser = await playwright.Chromium.LaunchAsync(new BrowserTypeLaunchOptions
                    {
                        Headless = true,
                        Args = new[]
                        {
                            "--no-sandbox",
                            "--disable-setuid-sandbox",
                            "--disable-gpu",
                            "--disable-dev-shm-usage",
                            "--disable-software-rasterizer"
                        }
                    });
                    var page = await browser.NewPageAsync();

                    for (int currentPage = 1; currentPage <= maxPages; currentPage++)
                    {
                        // Construir la URL con la página actual
                        string url = $"https://www.falabella.com.pe/falabella-pe/search?Ntt=mujer&f.derived.variant.sellerId=FALABELLA&facetSelected=true&sortBy=derived.price.search%2Casc&page={currentPage}";
                        Console.WriteLine($"Procesando página {currentPage}: {url}");

                        // Navega a la URL de los productos
                        await page.GotoAsync(url);

                        // Espera a que la página cargue los productos
                        await page.WaitForSelectorAsync("#testId-searchResults-products");

                        // Obtiene los productos después de que carguen
                        var productNodes = await page.QuerySelectorAllAsync("#testId-searchResults-products .grid-pod");

                        foreach (var productNode in productNodes)
                        {
                            var discountNode = await productNode.QuerySelectorAsync(".discount-badge-item");
                            if (discountNode != null)
                            {
                                var discountText = await discountNode.InnerTextAsync();
                                if (decimal.TryParse(discountText.Replace("%", "").Replace("-", ""), out decimal discountPercentage) && discountPercentage > 60)
                                {
                                    var nameNode = await productNode.QuerySelectorAsync(".pod-subTitle");
                                    var brandNode = await productNode.QuerySelectorAsync(".pod-title");
                                    var discountedPriceNode = await productNode.QuerySelectorAsync(".copy10");
                                    var linkNode = await productNode.QuerySelectorAsync("a.pod-link");
                                    var productUrl = await linkNode.GetAttributeAsync("href");

                                    products.Add(new Product
                                    {
                                        Name = await nameNode.InnerTextAsync(),
                                        Brand = brandNode != null ? await brandNode.InnerTextAsync() : "Sin marca",
                                        DiscountedPrice = discountedPriceNode != null ? await discountedPriceNode.InnerTextAsync() : "Precio no disponible",
                                        Discount = discountText,
                                        DiscountPercentage = discountPercentage,
                                        Link = productUrl
                                    });
                                }
                            }
                        }
                    }

                    await browser.CloseAsync();
                }

                // Ordenar los productos por el porcentaje de descuento de mayor a menor
                var sortedProducts = products.OrderByDescending(p => p.DiscountPercentage).ToList();

                return Ok(sortedProducts);
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
        public decimal DiscountPercentage { get; set; } // Nuevo campo para almacenar el porcentaje
        public string Link { get; set; }
    }
}
