// Pricing page toggle between monthly and annual plans
document.addEventListener('turbo:load', function() {
  const pricingToggle = document.getElementById('pricing-toggle');
  const monthlyPrices = document.querySelectorAll('.monthly-price');
  const annualPrices = document.querySelectorAll('.annual-price');
  const monthlyLabel = document.getElementById('monthly-label');
  const annualLabel = document.getElementById('annual-label');
  const subscribeButtons = document.querySelectorAll('.subscribe-button');
  
  if (pricingToggle) {
    pricingToggle.addEventListener('change', function() {
      if (this.checked) {
        // Annual pricing
        monthlyPrices.forEach(el => el.classList.add('d-none'));
        annualPrices.forEach(el => el.classList.remove('d-none'));
        monthlyLabel.classList.remove('text-primary', 'fw-bold');
        annualLabel.classList.add('text-primary', 'fw-bold');
        
        // Update subscribe buttons to use annual interval
        subscribeButtons.forEach(button => {
          const href = button.getAttribute('href');
          if (href) {
            button.setAttribute('href', href.replace('interval=month', 'interval=year'));
          }
        });
      } else {
        // Monthly pricing
        monthlyPrices.forEach(el => el.classList.remove('d-none'));
        annualPrices.forEach(el => el.classList.add('d-none'));
        monthlyLabel.classList.add('text-primary', 'fw-bold');
        annualLabel.classList.remove('text-primary', 'fw-bold');
        
        // Update subscribe buttons to use monthly interval
        subscribeButtons.forEach(button => {
          const href = button.getAttribute('href');
          if (href) {
            button.setAttribute('href', href.replace('interval=year', 'interval=month'));
          }
        });
      }
    });
  }
}); 